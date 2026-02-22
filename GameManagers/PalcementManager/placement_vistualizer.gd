extends Node3D
class_name PlacementVisualizer

@export_group("Visual Settings")
@export var valid_preview_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var invalid_preview_color: Color = Color(1.0, 0.5, 0.5, 0.8)
@export var debug_footprint_color: Color = Color(0.2, 0.6, 1.0, 0.2) # Debug 专属蓝色

var preview_root: Node3D
var preview_sprite: Sprite3D
var footprint_root: Node3D
var decal_material: StandardMaterial3D

# 🌟 新增：Debug 专属管理节点和材质
var debug_root: Node3D
var debug_material: StandardMaterial3D

func _ready() -> void:
	preview_root = Node3D.new()
	add_child(preview_root)
	footprint_root = Node3D.new()
	add_child(footprint_root)
	
	# 当前建造底板材质
	decal_material = StandardMaterial3D.new()
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	decal_material.no_depth_test = true
	
	# Debug 底板材质
	debug_root = Node3D.new()
	add_child(debug_root)
	debug_material = StandardMaterial3D.new()
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.no_depth_test = true
	debug_material.albedo_color = debug_footprint_color

func set_item(item: ItemData, radius: float = 0.5, cloned_sprite: Sprite3D = null) -> void:
	for child in footprint_root.get_children(): 
		child.queue_free()
		
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = radius
	c_mesh.bottom_radius = radius
	c_mesh.height = 0.02 
	c_mesh.radial_segments = 32 
	
	var c_mi = MeshInstance3D.new()
	c_mi.mesh = c_mesh
	c_mi.material_override = decal_material
	c_mi.position = Vector3(0, 0.01, 0)
	footprint_root.add_child(c_mi)

	if preview_sprite and is_instance_valid(preview_sprite):
		preview_sprite.queue_free()
	
	if cloned_sprite:
		preview_sprite = cloned_sprite
		preview_root.add_child(preview_sprite)
		preview_sprite.transparent = true
		preview_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISABLED
		preview_sprite.no_depth_test = true
		var mat = preview_sprite.material_override
		if mat: 
			preview_sprite.material_override = mat.duplicate()
			if preview_sprite.material_override is BaseMaterial3D:
				preview_sprite.material_override.no_depth_test = true
	else:
		hide_build_preview()

# 🌟 新增：全图 Debug 圆圈刷新逻辑
func update_debug_footprints(show: bool, placed_items: Array) -> void:
	if not show:
		debug_root.visible = false
		return
		
	debug_root.visible = true
	
	# 如果场景里的圆圈数量和普查局里的对不上（说明有新建或删除），就重新生成
	if debug_root.get_child_count() != placed_items.size():
		for child in debug_root.get_children():
			child.queue_free()
			
		for item in placed_items:
			var c_mesh = CylinderMesh.new()
			c_mesh.top_radius = item["radius"]
			c_mesh.bottom_radius = item["radius"]
			c_mesh.height = 0.02
			c_mesh.radial_segments = 32
			
			var c_mi = MeshInstance3D.new()
			c_mi.mesh = c_mesh
			c_mi.material_override = debug_material
			debug_root.add_child(c_mi)
			
	# 同步位置
	var children = debug_root.get_children()
	for i in range(placed_items.size()):
		if i < children.size():
			var pos_2d = placed_items[i]["pos"]
			children[i].global_position = Vector3(pos_2d.x, 0.015, pos_2d.y) # 比正常底板稍微高一点点防止闪烁

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
