extends Node3D
class_name PlacementVisualizer

@export_group("Visual Settings")
@export var radar_material: ShaderMaterial 
@export var base_cell_size: float = 1.0
@export var valid_preview_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var invalid_preview_color: Color = Color(1.0, 0.5, 0.5, 0.8)

var preview_root: Node3D
var preview_sprite: Sprite3D
var footprint_root: Node3D
var decal_material: StandardMaterial3D
var points_multimesh: MultiMeshInstance3D
@export var grid_radius: int = 10

func _ready() -> void:
	preview_root = Node3D.new()
	add_child(preview_root)
	footprint_root = Node3D.new()
	add_child(footprint_root)
	decal_material = StandardMaterial3D.new()
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# === 🎯 新增：让绿底板永远显示在最上层 (透视效果) ===
	decal_material.no_depth_test = true
	_init_point_cloud_radar()

func _init_point_cloud_radar() -> void:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(0.5, 0.5) 
	if radar_material: mesh.material = radar_material
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false 
	multimesh.use_custom_data = true 
	multimesh.mesh = mesh 
	multimesh.instance_count = (grid_radius * 2 + 1) ** 2
	points_multimesh = MultiMeshInstance3D.new()
	points_multimesh.multimesh = multimesh
	add_child(points_multimesh)

func set_item(item: ItemData, footprint_cells: Array[Vector2i], cloned_sprite: Sprite3D = null) -> void:
	# 1. 清空之前的节点
	for child in footprint_root.get_children(): 
		child.queue_free()
		
	# 🎯 2. 核心修改：不再遍历 footprint_cells，而是直接在中心画一个十字
	var cross_length = base_cell_size * 0.8  # 十字的长度（占格子的 80%）
	var cross_thickness = base_cell_size * 0.4 # 十字的粗细
	
	# 横向矩形
	var h_mesh = PlaneMesh.new()
	h_mesh.size = Vector2(cross_length, cross_thickness)
	var h_mi = MeshInstance3D.new()
	h_mi.mesh = h_mesh
	h_mi.material_override = decal_material
	h_mi.position = Vector3(0, 0.02, 0)
	footprint_root.add_child(h_mi)
	
	# 纵向矩形
	var v_mesh = PlaneMesh.new()
	v_mesh.size = Vector2(cross_thickness, cross_length)
	var v_mi = MeshInstance3D.new()
	v_mi.mesh = v_mesh
	v_mi.material_override = decal_material
	v_mi.position = Vector3(0, 0.02, 0)
	footprint_root.add_child(v_mi)

	if preview_sprite and is_instance_valid(preview_sprite):
		preview_sprite.queue_free()
	
	if cloned_sprite:
		preview_sprite = cloned_sprite
		preview_root.add_child(preview_sprite)
		preview_sprite.transparent = true
		preview_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISABLED
		# === 🎯 新增：让物体虚影无视地形遮挡 (全息X光效果) ===
		preview_sprite.no_depth_test = true
		var mat = preview_sprite.material_override
		
		if mat: 
			preview_sprite.material_override = mat.duplicate()
			if preview_sprite.material_override is BaseMaterial3D:
				preview_sprite.material_override.no_depth_test = true
	else:
		hide_build_preview()

# === 🎯 核心变更：战棋风格实心方块雷达 ===
func update_radar(center_pos: Vector3, _mouse_pos: Vector3) -> void:
	# 注意：第二个参数 mouse_pos 现在没用了，因为我们是“以格子为中心”而不是“以鼠标像素为中心”
	# 不过为了保持接口兼容，参数留着也没事，加个下划线 _mouse_pos 表示暂不使用
	
	points_multimesh.visible = true
	var index = 0
	
	# 现在的逻辑非常纯粹：遍历多少格，就显示多少格
	# 范围完全由 export var grid_radius 控制
	for x in range(-grid_radius, grid_radius + 1):
		for z in range(-grid_radius, grid_radius + 1):
			# 1. 算出点的世界坐标
			var point_world_pos = center_pos + Vector3(x * base_cell_size, 0.02, z * base_cell_size)
			var cell_coord = Vector2i(round(point_world_pos.x / base_cell_size), round(point_world_pos.z / base_cell_size))
			
			# 2. 查占用状态
			var is_occupied = ItemGridManager.is_cell_occupied(cell_coord)
			
			# 3. 设置位置
			var t = Transform3D().translated(point_world_pos)
			points_multimesh.multimesh.set_instance_transform(index, t)
			
			# 4. 设置颜色与透明度 (硬边缘)
			# alpha = 1.0 (完全显示)。如果你觉得太亮，可以改成 0.5 或者 0.3
			var alpha = 1.0 
			
			# 传给 Shader：R通道=是否占用, G通道=透明度
			points_multimesh.multimesh.set_instance_custom_data(index, Color(1.0 if is_occupied else 0.0, alpha, 0.0, 0.0))
			
			index += 1

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

func hide_build_preview() -> void:
	preview_root.visible = false
	footprint_root.visible = false

func hide_all() -> void:
	hide_build_preview()
	points_multimesh.visible = false
