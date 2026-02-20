extends Node3D

@export_group("Grid System")
@export var base_cell_size: float = 1.0 

@export var current_item: ItemData:
	set(value):
		current_item = value
		if is_node_ready():
			_update_item_data()
			_refresh_cursor() # 换物品时顺便换鼠标

@export_group("References")
# 记得把你的 CameraRig 节点拖进来，脚本类型要是 CameraRig
@export var camera_rig: CameraRig             
@export var visualizer: PlacementVisualizer 

@export_group("Editor Tools")
@export var delete_highlight_color: Color = Color(1.0, 0.2, 0.2, 1.0) 

var is_building_mode: bool = true        
var is_delete_mode: bool = false 

var current_footprint_cells: Array[Vector2i] = [Vector2i(0, 0)]
var hovered_object: Node3D = null 

func _ready() -> void:
	_update_item_data()
	if is_building_mode:
		GlobalCursor.set_cursor_state(CursorVisualizer.CursorState.BUILD)
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
	if Input.is_action_just_pressed("Delete_Mode_Toggle"): 
		_toggle_delete_mode()

	if not is_building_mode or not camera_rig or not visualizer:
		if visualizer: visualizer.hide_all()
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	if is_delete_mode:
		# 🎯 饥荒流：删除模式下，直接用鼠标射线去摸物理碰撞体
		if visualizer: visualizer.hide_all() # 隐藏地面的十字雷达
		_handle_delete_mode_raycast(mouse_pos)
		
	else:
		# 🧱 网格流：建造模式下，射线找地面计算落点
		var cam = camera_rig.camera
		var ground_plane = Plane(Vector3.UP, 0.0)
		var ray_origin = cam.project_ray_origin(mouse_pos)
		var intersection = ground_plane.intersects_ray(ray_origin, cam.project_ray_normal(mouse_pos))
		
		if intersection != null:
			var snapped_pos = snap_to_grid(intersection)
			visualizer.update_radar(snapped_pos, intersection)
			if current_item:
				_handle_build_mode(snapped_pos)
		else:
			if visualizer: visualizer.hide_all()

# === 状态与光标管理 ===
func _toggle_delete_mode() -> void:
	is_delete_mode = !is_delete_mode
	_reset_hovered_object() 
	
	if is_delete_mode:
		# 🎯 核心修复：进入删除模式，强制隐藏建造虚影！
		if visualizer: visualizer.hide_build_preview()
		print("进入删除模式")
	else:
		print("回到建造模式")
		
	_refresh_cursor()

# === 删除逻辑 ===
# === 全新饥荒流点选逻辑 ===
# === 全新饥荒流点选逻辑 ===
func _handle_delete_mode_raycast(mouse_pos: Vector2) -> void:
	var cam = camera_rig.camera
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# 🌟 设置检测层级为 2
	query.collision_mask = 2 
	
	# 🌟 绝杀修复：强制射线检测 Area3D（引擎默认是 false）
	query.collide_with_areas = true 
	
	var result = space_state.intersect_ray(query)
	var target_node = null
	
	if result:
		var hit_collider = result.collider
		
		var curr = hit_collider
		while curr and curr != get_tree().root:
			if curr.has_node("DestructibleComponent"):
				target_node = curr
				break
			curr = curr.get_parent()
			
	if target_node != hovered_object:
		_reset_hovered_object()
		if target_node:
			hovered_object = target_node
			_tint_object(hovered_object, delete_highlight_color)
	
	if Input.is_action_just_pressed("left_mouse"):
		if hovered_object:
			var comp = hovered_object.get_node_or_null("DestructibleComponent")
			if comp:
				comp.delete_instantly()
			else:
				hovered_object.queue_free()
			hovered_object = null

# === 建造逻辑 ===
func _handle_build_mode(snapped_pos: Vector3) -> void:
	var covered_cells = get_covered_cells(snapped_pos)
	var is_terrain = current_item.is_terrain()
	var can_place = is_placement_valid(covered_cells, is_terrain)
	
	visualizer.update_build_preview(snapped_pos, can_place)
	
	if Input.is_action_just_pressed("left_mouse") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.is_action_just_pressed("left_mouse"):
			if can_place:
				place_item(snapped_pos, covered_cells)

# === 辅助函数 ===
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

	WorldManager.register_item(covered_cells, new_instance, is_terrain)

	var destructible = new_instance.get_node_or_null("DestructibleComponent")
	if destructible:
		# 🎯 修复：传入两个参数，确保组件知道自己是啥
		destructible.setup(covered_cells, is_terrain)

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
	
func _refresh_cursor() -> void:
	
	if is_delete_mode:
		# 假设你在 CameraVisualizer 里定义了 DELETE 状态
		GlobalCursor.set_cursor_state(CursorVisualizer.CursorState.DELETE)
		print("Delete")
	else:
		if current_item:
			GlobalCursor.set_cursor_state(CursorVisualizer.CursorState.BUILD)
			print("BUILD")
		else:
			GlobalCursor.set_cursor_state(CursorVisualizer.CursorState.NORMAL)
