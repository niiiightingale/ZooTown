extends Node3D
class_name PlacementVisualizer

@export_group("Visual Settings")
@export var radar_material: ShaderMaterial 
@export var base_cell_size: float = 1.0

# 虚影颜色配置
@export var valid_preview_color: Color = Color(1.0, 1.0, 1.0, 0.8)   # 绿灯颜色
@export var invalid_preview_color: Color = Color(1.0, 0.5, 0.5, 0.8) # 红灯颜色

var global_pixel_size: float = 0.015625

var preview_root: Node3D    # 替身根节点 (挂载建造虚影)
var preview_sprite: Sprite3D
var footprint_root: Node3D  # 绿底板根节点
var decal_material: StandardMaterial3D

var points_multimesh: MultiMeshInstance3D
var grid_radius: int = 10

func _ready() -> void:
	# 1. 初始化节点结构
	preview_root = Node3D.new()
	add_child(preview_root)
	
	footprint_root = Node3D.new()
	add_child(footprint_root)
	
	decal_material = StandardMaterial3D.new()
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# 2. 初始化雷达
	_init_point_cloud_radar()

func _init_point_cloud_radar() -> void:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(0.5, 0.5) 
	
	if radar_material:
		mesh.material = radar_material
	else:
		push_warning("视觉总监警告：你忘记在检查器里配置 radar_material 了！")
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false 
	multimesh.use_custom_data = true 
	multimesh.mesh = mesh 
	
	var side_length = grid_radius * 2 + 1
	multimesh.instance_count = side_length * side_length 
	
	points_multimesh = MultiMeshInstance3D.new()
	points_multimesh.multimesh = multimesh
	add_child(points_multimesh)

# ==========================================
# 🎯 核心变更：分离雷达更新与虚影更新
# ==========================================

# 1. 只更新雷达（编辑模式通用背景）
func update_radar(center_pos: Vector3, mouse_pos: Vector3) -> void:
	points_multimesh.visible = true
	var index = 0
	var max_dist = grid_radius * base_cell_size
	var mouse_pos_2d = Vector2(mouse_pos.x, mouse_pos.z)
	
	for x in range(-grid_radius, grid_radius + 1):
		for z in range(-grid_radius, grid_radius + 1):
			var point_world_pos = center_pos + Vector3(x * base_cell_size, 0.02, z * base_cell_size)
			var cell_coord = Vector2i(round(point_world_pos.x / base_cell_size), round(point_world_pos.z / base_cell_size))
			
			# 视觉总监直接跟银行查账！
			var is_occupied = WorldManager.is_cell_occupied(cell_coord, false)
			
			var dist = Vector2(point_world_pos.x, point_world_pos.z).distance_to(mouse_pos_2d)
			var alpha = 1.0 - smoothstep(max_dist - 2.0, max_dist, dist)
			
			var t = Transform3D().translated(point_world_pos)
			points_multimesh.multimesh.set_instance_transform(index, t)
			
			points_multimesh.multimesh.set_instance_custom_data(index, Color(1.0 if is_occupied else 0.0, alpha, 0.0, 0.0))
			index += 1

# 2. 只更新建造虚影（仅建造模式用）
func update_build_preview(pos: Vector3, is_valid: bool) -> void:
	if not preview_sprite: return
	
	preview_root.visible = true
	footprint_root.visible = true
	
	preview_root.global_position = pos
	footprint_root.global_position = pos
	
	if is_valid:
		decal_material.albedo_color = Color(0.1, 0.9, 0.1, 0.3) 
		preview_sprite.modulate = valid_preview_color 
	else:
		decal_material.albedo_color = Color(1.0, 0.0, 0.0, 0.5) 
		preview_sprite.modulate = invalid_preview_color

# 3. 隐藏建造虚影（进入删除模式或退出时用）
func hide_build_preview() -> void:
	preview_root.visible = false
	footprint_root.visible = false

# 4. 完全关闭（退出编辑模式）
func hide_all() -> void:
	hide_build_preview()
	points_multimesh.visible = false

# ==========================================
# 物品切换逻辑
# ==========================================
func set_item(item: ItemData, footprint_cells: Array[Vector2i], cloned_sprite: Sprite3D = null) -> void:
	# 1. 重建地上的绿底板
	for child in footprint_root.get_children():
		child.queue_free()
		
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(base_cell_size * 0.95, base_cell_size * 0.95)
	for offset in footprint_cells:
		var mi = MeshInstance3D.new()
		mi.mesh = plane_mesh
		mi.material_override = decal_material
		mi.position = Vector3(offset.x * base_cell_size, 0.02, offset.y * base_cell_size)
		footprint_root.add_child(mi)

	# 2. 清理旧虚影
	if preview_sprite != null and is_instance_valid(preview_sprite):
		preview_sprite.queue_free()
		preview_sprite = null

	# 3. 挂载新克隆体
	if cloned_sprite:
		preview_sprite = cloned_sprite
		preview_root.add_child(preview_sprite)
		
		# 强行开启半透明混合
		preview_sprite.transparent = true
		preview_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISABLED
		
		var mat = preview_sprite.material_override
		if mat: preview_sprite.material_override = mat.duplicate()
	else:
		hide_build_preview()
