extends Node3D
class_name PlacementManager

@export_group("References")
@export var visualizer: PlacementVisualizer 
@export var terrain_manager: TerrainManager # 必须拉进来，找地基局问话用！

@export_group("Debug")
@export var show_debug_footprints: bool = true # 勾选后就能看到满地的势力圈！
var current_item: ItemData = null

func _ready() -> void:
	GameState.brush_changed.connect(_on_brush_changed)

func _process(_delta: float) -> void:
	if visualizer and ItemGridManager:
		visualizer.update_debug_footprints(show_debug_footprints, ItemGridManager.placed_items)
		
	if GameState.current_mode not in [GameState.Mode.BUILD_ITEM, GameState.Mode.DELETE_ITEM, GameState.Mode.NORMAL]:
		return

	match GameState.current_mode:
		GameState.Mode.BUILD_ITEM:
			_process_build_mode()
		GameState.Mode.DELETE_ITEM:
			_process_delete_mode()
		GameState.Mode.NORMAL:
			_process_normal_mode()

func _on_brush_changed(new_brush: Resource) -> void:
	if new_brush is ItemData:
		current_item = new_brush
		_update_item_data()
	else:
		current_item = null
		if visualizer: visualizer.hide_all()

# ==========================================
# 🌟 自由建造模式核心
# ==========================================
func _process_build_mode() -> void:
	if not visualizer or not current_item: return
	
	if MouseScanner.is_mouse_on_ground:
		var world_pos = MouseScanner.ground_position
		# 提取 X 和 Z 作为 2D 平面坐标，交给数学计算用
		var pos_2d = Vector2(world_pos.x, world_pos.z) 
		
		var can_place = is_placement_valid(world_pos, pos_2d) 
		
		# 🎯 彻底自由：不再传 snapped_pos，直接传世界坐标，虚影丝滑无极移动！

		visualizer.update_build_preview(world_pos, can_place)
		
		if Input.is_action_just_pressed("left_mouse") and can_place:
			place_item(world_pos, pos_2d)
	else:
		visualizer.hide_all()

func is_placement_valid(world_pos: Vector3, pos_2d: Vector2) -> bool:
	var radius = current_item.footprint_radius
	
	# 1. 问普查局：这片空地有被别人（按圆的半径）占用了吗？
	# 注意：如果你把 ItemGridManager 改名了，这里请用新名字
	if not ItemGridManager.is_position_valid(pos_2d, radius):
		return false
		
	# 2. 问地基局：我脚下踩的这块地砖，符合我的要求吗？
	if terrain_manager:
		# 🌟 跨维度翻译：把极度精确的自由坐标，除以 2.0 向下取整，算出它踩在了地皮的哪个格子上
		var logic_x = floor(world_pos.x / 2.0)
		var logic_z = floor(world_pos.z / 2.0)
		var logic_cell = Vector2i(logic_x, logic_z)
		
		var current_layer = terrain_manager.get_highest_layer(logic_cell)
		if current_layer not in current_item.allowed_layers:
			return false
	else:
		print("⚠️ 警告：PlacementManager 未绑定 TerrainManager！")
		return false
		
	return true

func place_item(world_pos: Vector3, pos_2d: Vector2) -> void:
	if not current_item or not current_item.prefab: return
	
	var new_instance = current_item.prefab.instantiate()
	add_child(new_instance)
	new_instance.global_position = Vector3(world_pos.x, 0.0, world_pos.z)

	# 登记到人口普查局
	ItemGridManager.register_item(new_instance, pos_2d, current_item.footprint_radius)

	# ⚠️ 注意：因为你的破坏组件以前需要接收数组，现在自由网格不需要了
	# 只要它上面有 DestructibleComponent，玩家点拆除时直接 queue_free 掉实体
	# 普查局的“验尸”机制会在下一帧自动把它除名，完美闭环！

# ==========================================
# 交互与删除保持极简
# ==========================================
func _process_delete_mode() -> void:
	if visualizer: visualizer.hide_all()
	var target = MouseScanner.hovered_object
	if Input.is_action_pressed("left_mouse") and target:
		var comp = target.get_node_or_null("DestructibleComponent")
		if comp:
			comp.delete_instantly()
		else:
			target.queue_free()

func _process_normal_mode() -> void:
	if visualizer: visualizer.hide_all()
	var target = MouseScanner.hovered_object
	if Input.is_action_just_pressed("left_mouse") and target:
		print("触发普通互动！对象是：", target.name)

# ==========================================
# 虚影生成
# ==========================================
func _update_item_data() -> void:
	var sprite_clone: Sprite3D = null 
	
	if current_item and current_item.prefab:
		var temp_instance = current_item.prefab.instantiate()
		for child in temp_instance.get_children():
			if child is Sprite3D:
				sprite_clone = child.duplicate()
				for grandchild in sprite_clone.get_children():
					grandchild.free()
				break 
		temp_instance.free() 
	
	if visualizer:
		# 🎯 传递当前物品的半径（代替以前的空数组）
		var radius = current_item.footprint_radius if current_item else 0.5
		visualizer.set_item(current_item, radius, sprite_clone)
