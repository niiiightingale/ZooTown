extends Node3D

@export_group("Grid System")
@export var base_cell_size: float = 1.0 

@export var current_item: ItemData:
	set(value):
		current_item = value
		if is_node_ready():
			_update_item_data()

@export_group("References")
@export var camera_rig: CameraRig           
@export var visualizer: PlacementVisualizer 

@export_group("Editor Tools")
@export var trash_cursor: Texture2D # 记得拖入垃圾桶图片！
@export var delete_highlight_color: Color = Color(1.0, 0.2, 0.2, 1.0) # 变红警告色

var is_building_mode: bool = true        
var is_delete_mode: bool = false # 状态机：是否处于删除模式

var current_footprint_cells: Array[Vector2i] = [Vector2i(0, 0)]
var hovered_object: Node3D = null # 当前被鼠标指着的高亮物体

func _ready() -> void:
	_update_item_data()
	await get_tree().process_frame
	_refresh_cursor()

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
				break 
				
		temp_instance.free() 
	
	if visualizer:
		visualizer.set_item(current_item, current_footprint_cells, sprite_clone)

func _process(_delta: float) -> void:
	# === 1. 监听模式切换 (防止机关枪连发，需配合 Input Map) ===
	if Input.is_action_just_pressed("Delete_Mode_Toggle"): 
		_toggle_delete_mode()

	if not is_building_mode or not camera_rig or not camera_rig.camera or not visualizer:
		if visualizer: visualizer.hide_all()
		return
		
	var virtual_mouse_pos = camera_rig.cursor_pos
	var cam = camera_rig.camera
	var ground_plane = Plane(Vector3.UP, 0.0)
	var ray_origin = cam.project_ray_origin(virtual_mouse_pos)
	var intersection = ground_plane.intersects_ray(ray_origin, cam.project_ray_normal(virtual_mouse_pos))
	
	if intersection != null:
		var snapped_pos = snap_to_grid(intersection)
		
		# === 🌟 核心：雷达常驻 (编辑模式通用背景) ===
		visualizer.update_radar(snapped_pos, intersection)
		
		# === 分支逻辑：建造 vs 删除 ===
		if is_delete_mode:
			_handle_delete_mode(snapped_pos)
		elif current_item:
			_handle_build_mode(snapped_pos)
	else:
		if visualizer: visualizer.hide_all()

# ==========================================
# 状态切换逻辑
# ==========================================
func _toggle_delete_mode() -> void:
	is_delete_mode = !is_delete_mode
	_reset_hovered_object() # 切换前先把高亮清空
	
	if is_delete_mode:
		# 告诉 CameraRig 换成删除图标
		camera_rig.set_cursor_state(CursorVisualizer.CursorState.DELETE)
		# === 🎯 核心修复：进入删除模式时，必须强制按住视觉总监的手，让他把虚影藏起来！ ===
		if visualizer: visualizer.hide_build_preview()
		print("进入删除模式")
	else:
		# 告诉 CameraRig 换回建造图标（或普通图标）
		if current_item:
			camera_rig.set_cursor_state(CursorVisualizer.CursorState.BUILD)
			print("进入建造模式")
		else:
			camera_rig.set_cursor_state(CursorVisualizer.CursorState.NORMAL)
			print("进入默认模式")

# ==========================================
# 删除模式逻辑 (高亮 + 智能关联 + 剥洋葱)
# ==========================================
func _handle_delete_mode(snapped_pos: Vector3) -> void:
	var cell = Vector2i(round(snapped_pos.x / base_cell_size), round(snapped_pos.z / base_cell_size))
	
	# 1. 索敌 (剥洋葱：先找物体，没有物体再找地形)
	var target_node = WorldManager.get_node_at_cell(cell, false)
	if target_node == null:
		target_node = WorldManager.get_node_at_cell(cell, true)
	
	# 2. 高亮反馈
	if target_node != hovered_object:
		_reset_hovered_object() # 还原上一个
		if target_node:
			hovered_object = target_node
			_tint_object(hovered_object, delete_highlight_color) # 变红这一个
	
	# 3. 点击执行死刑
	if Input.is_action_just_pressed("left_mouse") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.is_action_just_pressed("left_mouse") and hovered_object:
			# 优先尝试使用组件进行“智能删除”
			var comp = hovered_object.get_node_or_null("DestructibleComponent")
			if comp:
				comp.delete_instantly()
			else:
				# 保底删除 (不推荐，建议所有物体都挂组件)
				hovered_object.queue_free()
			
			hovered_object = null

# ==========================================
# 建造模式逻辑
# ==========================================
func _handle_build_mode(snapped_pos: Vector3) -> void:
	var covered_cells = get_covered_cells(snapped_pos)
	var is_terrain = current_item.is_terrain()
	var can_place = is_placement_valid(covered_cells, is_terrain)
	
	# 仅更新虚影 (雷达在 process 里统一更了)
	visualizer.update_build_preview(snapped_pos, can_place)
	
	if Input.is_action_just_pressed("left_mouse") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.is_action_just_pressed("left_mouse"):
			if can_place:
				place_item(snapped_pos, covered_cells)

# ==========================================
# 辅助函数
# ==========================================
func _tint_object(node: Node3D, color: Color) -> void:
	if "modulate" in node:
		node.modulate = color
	else:
		for child in node.get_children():
			if child is Sprite3D or child is AnimatedSprite3D:
				child.modulate = color

func _reset_hovered_object() -> void:
	if hovered_object and is_instance_valid(hovered_object):
		_tint_object(hovered_object, Color.WHITE)
	hovered_object = null

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

func is_placement_valid(covered_cells: Array[Vector2i], is_terrain: bool) -> bool:
	for cell in covered_cells:
		if WorldManager.is_cell_occupied(cell, is_terrain):
			return false 
	return true

func place_item(world_pos: Vector3, covered_cells: Array[Vector2i]) -> void:
	if not current_item or not current_item.prefab: return
	var is_terrain = current_item.is_terrain()
	var new_instance = current_item.prefab.instantiate()
	add_child(new_instance)
	
	if is_terrain:
		var height = (current_item.terrain_rank * 0.01) + randf_range(0.0, 0.005)
		new_instance.global_position = Vector3(world_pos.x, height, world_pos.z)
		new_instance.rotation_degrees.y = [0, 90, 180, 270].pick_random()
	else:
		new_instance.global_position = Vector3(world_pos.x, 0.0, world_pos.z)

	# 1. 银行注册
	WorldManager.register_item(covered_cells, new_instance, is_terrain)

	# 2. 注入组件数据 (必须做这一步，DestructibleComponent 才能工作)
	var destructible = new_instance.get_node_or_null("DestructibleComponent")
	if destructible:
		destructible.setup(covered_cells, is_terrain)
# === 封装：统一刷新鼠标状态 ===
func _refresh_cursor() -> void:
	if not camera_rig: return
	
	if is_delete_mode:
		camera_rig.set_cursor_state(CursorVisualizer.CursorState.DELETE)
	else:
		if current_item:
			camera_rig.set_cursor_state(CursorVisualizer.CursorState.BUILD)
		else:
			camera_rig.set_cursor_state(CursorVisualizer.CursorState.NORMAL)
