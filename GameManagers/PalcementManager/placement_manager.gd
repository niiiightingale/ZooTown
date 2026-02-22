extends Node3D
class_name PlacementManager

@export_group("Grid System")
@export var base_cell_size: float = 1.0 

@export_group("References")
@export var visualizer: PlacementVisualizer 
# 🌟 新增：把你的 TerrainManager 节点拖到这个槽位里！
@export var terrain_manager: TerrainManager

var current_footprint_cells: Array[Vector2i] = [Vector2i(0, 0)]
var current_item: ItemData = null

func _ready() -> void:
	# 🎯 核心改动 1：不再自己瞎定初始状态，而是老老实实监听老板（GameState）的画笔变化
	GameState.brush_changed.connect(_on_brush_changed)

func _process(_delta: float) -> void:
	# 🎯 核心改动 2：所有的 Input 监听全部删掉！
	# 只根据 GameState 当前的模式来干活
	
	if GameState.current_mode not in [GameState.Mode.BUILD_ITEM, GameState.Mode.DELETE_ITEM, GameState.Mode.NORMAL]:
		return

	match GameState.current_mode:
		GameState.Mode.BUILD_ITEM:
			_process_build_mode()
		GameState.Mode.DELETE_ITEM:
			_process_delete_mode()
		GameState.Mode.NORMAL:
			_process_normal_mode()

# ==========================================
# 📡 接收上级指令
# ==========================================
func _on_brush_changed(new_brush: Resource) -> void:
	# 如果收到的是物件画笔，更新自己的模型虚影
	if new_brush is ItemData:
		current_item = new_brush
		_update_item_data()
	else:
		current_item = null
		if visualizer: visualizer.hide_all()

# ==========================================
# 分支逻辑：建造
# ==========================================
func _process_build_mode() -> void:
	if not visualizer or not current_item: return
	
	if MouseScanner.is_mouse_on_ground:
		var snapped_pos = snap_to_grid(MouseScanner.ground_position)
		var covered_cells = get_covered_cells(snapped_pos)
		var can_place = is_placement_valid(covered_cells) 
		
		visualizer.update_radar(snapped_pos, MouseScanner.ground_position)
		visualizer.update_build_preview(snapped_pos, can_place)
		
		if Input.is_action_just_pressed("left_mouse") and can_place:
			place_item(snapped_pos, covered_cells)
	else:
		visualizer.hide_all()

# ==========================================
# 分支逻辑：删除
# ==========================================
func _process_delete_mode() -> void:
	if visualizer: visualizer.hide_all()
	var target = MouseScanner.hovered_object
	if Input.is_action_just_pressed("left_mouse") and target:
		var comp = target.get_node_or_null("DestructibleComponent")
		if comp:
			comp.delete_instantly()
		else:
			target.queue_free()

# ==========================================
# 分支逻辑：普通互动
# ==========================================
func _process_normal_mode() -> void:
	if visualizer: visualizer.hide_all()
	var target = MouseScanner.hovered_object
	if Input.is_action_just_pressed("left_mouse") and target:
		print("触发普通互动！对象是：", target.name)

# ==========================================
# 摆放与虚影生成逻辑 (保持不变)
# ==========================================
func _update_item_data() -> void:
	current_footprint_cells = [Vector2i(0, 0)] 
	var sprite_clone: Sprite3D = null 
	
	if current_item and current_item.prefab:
		var temp_instance = current_item.prefab.instantiate()
		var comp = temp_instance.get_node_or_null("FootprintComponent")
		if comp: 
			current_footprint_cells = comp.occupied_cells.duplicate()
			
		for child in temp_instance.get_children():
			if child is Sprite3D:
				sprite_clone = child.duplicate()
				for grandchild in sprite_clone.get_children():
					grandchild.free()
				break 
		temp_instance.free() 
	
	if visualizer:
		visualizer.set_item(current_item, current_footprint_cells, sprite_clone)

func place_item(world_pos: Vector3, covered_cells: Array[Vector2i]) -> void:
	if not current_item or not current_item.prefab: return
	
	var new_instance = current_item.prefab.instantiate()
	add_child(new_instance)
	new_instance.global_position = Vector3(world_pos.x, 0.0, world_pos.z)

	ItemGridManager.register_item(covered_cells, new_instance)

	var destructible = new_instance.get_node_or_null("DestructibleComponent")
	if destructible: 
		destructible.setup(covered_cells)

func snap_to_grid(pos: Vector3) -> Vector3:
	var step = base_cell_size
	return Vector3(round(pos.x / step) * step, 0.0, round(pos.z / step) * step)

func get_covered_cells(snapped_pos: Vector3) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var base_x = int(round(snapped_pos.x / base_cell_size))
	var base_z = int(round(snapped_pos.z / base_cell_size))
	for offset in current_footprint_cells:
		cells.append(Vector2i(base_x + offset.x, base_z + offset.y))
	return cells

func is_placement_valid(covered_cells: Array[Vector2i]) -> bool:
	for cell in covered_cells:
		# 1. 问实体建筑局：这里有其他树或建筑挡着吗？
		if ItemGridManager.is_cell_occupied(cell): 
			return false 
			
		# 2. 问地基局：脚下的地形层级达标吗？
		if terrain_manager:
			var current_layer = terrain_manager.get_highest_layer(cell)
			
			# 如果脚下的最高层级（比如是 1），不在物品允许的层级列表（比如 [0]）里，直接拒绝！
			if current_layer not in current_item.allowed_layers:
				print("不符合！")
				return false
		else:
			print("⚠️ 警告：PlacementManager 没有绑定 TerrainManager！")
			return false # 安全起见，没连网就不让建
			
	return true
