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
var grid_radius: int = 10

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
	for child in footprint_root.get_children(): child.queue_free()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(base_cell_size * 0.95, base_cell_size * 0.95)
	for offset in footprint_cells:
		var mi = MeshInstance3D.new()
		mi.mesh = plane_mesh
		mi.material_override = decal_material
		mi.position = Vector3(offset.x * base_cell_size, 0.02, offset.y * base_cell_size)
		footprint_root.add_child(mi)

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

func update_radar(center_pos: Vector3, mouse_pos: Vector3) -> void:
	points_multimesh.visible = true
	var index = 0
	var max_dist = grid_radius * base_cell_size
	var mouse_pos_2d = Vector2(mouse_pos.x, mouse_pos.z)
	for x in range(-grid_radius, grid_radius + 1):
		for z in range(-grid_radius, grid_radius + 1):
			var pt = center_pos + Vector3(x * base_cell_size, 0.02, z * base_cell_size)
			var cell = Vector2i(round(pt.x/base_cell_size), round(pt.z/base_cell_size))
			var is_occ = WorldManager.is_cell_occupied(cell, false)
			var dist = Vector2(pt.x, pt.z).distance_to(mouse_pos_2d)
			var alpha = 1.0 - smoothstep(max_dist-2.0, max_dist, dist)
			var t = Transform3D().translated(pt)
			points_multimesh.multimesh.set_instance_transform(index, t)
			points_multimesh.multimesh.set_instance_custom_data(index, Color(1.0 if is_occ else 0.0, alpha, 0.0, 0.0))
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
