extends Node
class_name TerrainManager

const TILE_PIXEL_SIZE = 128
const TILE_3D_SIZE = 2.0 
const Y_STEP = 0.002 

@export_group("Initial Map Generation")
@export var base_terrain: TerrainData      
@export var initial_map_radius: int = 10   

const NEIGHBOUR_RULES = {
	[1, 1, 1, 1]: Vector2i(2, 1), [0, 0, 0, 1]: Vector2i(1, 3),
	[0, 0, 1, 0]: Vector2i(0, 0), [0, 1, 0, 0]: Vector2i(0, 2),
	[1, 0, 0, 0]: Vector2i(3, 3), [0, 1, 0, 1]: Vector2i(1, 0),
	[1, 0, 1, 0]: Vector2i(3, 2), [0, 0, 1, 1]: Vector2i(3, 0),
	[1, 1, 0, 0]: Vector2i(1, 2), [0, 1, 1, 1]: Vector2i(1, 1),
	[1, 0, 1, 1]: Vector2i(2, 0), [1, 1, 0, 1]: Vector2i(2, 2),
	[1, 1, 1, 0]: Vector2i(3, 1), [0, 1, 1, 0]: Vector2i(2, 3),
	[1, 0, 0, 1]: Vector2i(0, 1)
}

var map_data: Dictionary = {}
var map_nodes: Dictionary = {}
var terrain_config: Dictionary = {}

func _ready() -> void:
	GameState.brush_changed.connect(_on_brush_changed)
	if base_terrain:
		register_terrain(base_terrain)
		_generate_initial_map()
	else:
		print("🚨 [严重警告] TerrainManager 右侧未设置 Base Terrain！开局地皮生成失败！")

func _on_brush_changed(new_brush: Resource) -> void:
	if new_brush is TerrainData:
		register_terrain(new_brush)
		print("RegistTerrain")

func register_terrain(res: TerrainData) -> void:
	if res == null:
		return
	terrain_config[res.id] = {
		"layer": res.layer,
		"texture": res.texture,
		"sound": res.place_sound,
		"use_world_space": res.use_world_space_texture,
		"fill_texture": res.fill_texture,
		"fill_scale": res.fill_scale,
		"border_texture": res.border_texture
	}
	print("🌍 [TerrainManager] 已注册地皮：", res.id, " | 层级:", res.layer)

func _generate_initial_map() -> void:
	if not base_terrain: return
	print("🌍 开始生成初始地图 (半径", initial_map_radius, ")...")
	for x in range(-initial_map_radius, initial_map_radius + 1):
		for z in range(-initial_map_radius, initial_map_radius + 1):
			set_terrain(Vector2i(x, z), base_terrain.id, true, true) # 传入静默模式避免刷屏
	print("✅ 初始地图生成完毕！共生成字典节点数：", map_data.size())

var last_painted_cell: Vector2i = Vector2i(-99999, -99999)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_mode not in [GameState.Mode.BUILD_TERRAIN, GameState.Mode.DELETE_TERRAIN]:
		return
	var is_click = event is InputEventMouseButton and event.pressed
	var is_drag = event is InputEventMouseMotion
	
	if not (is_click or is_drag): 
		if event is InputEventMouseButton and not event.pressed:
			last_painted_cell = Vector2i(-99999, -99999)
		return

	var is_interacting = false
	if is_click:
		is_interacting = event.button_index == MOUSE_BUTTON_LEFT
	elif is_drag:
		is_interacting = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
	if not is_interacting:
		return

	var camera = get_viewport().get_camera_3d()
	if not camera: 
		print("⚠️ 找不到 3D 摄像机！")
		return
	
	var mouse_pos = event.position
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var ground_plane = Plane(Vector3.UP, 0.0)
	var hit_position = ground_plane.intersects_ray(ray_origin, ray_dir)
	
	if hit_position != null:
		var grid_pos = _world_to_grid(hit_position)
		if grid_pos == last_painted_cell:
			return
		last_painted_cell = grid_pos
		
		match GameState.current_mode:
			GameState.Mode.BUILD_TERRAIN:
				_process_build_mode(grid_pos)
			GameState.Mode.DELETE_TERRAIN:
				_process_delete_mode(grid_pos)

func _world_to_grid(hit_position: Vector3) -> Vector2i:
	var grid_x = floor(hit_position.x / TILE_3D_SIZE)
	var grid_z = floor(hit_position.z / TILE_3D_SIZE)
	return Vector2i(grid_x, grid_z)

func _process_build_mode(grid_pos: Vector2i) -> void:
	if GameState.current_brush is TerrainData:
		var brush = GameState.current_brush
		
		# 1. 安全检查：如果这个格子连数据都没有（虚空），绝对不能放
		if not map_data.has(grid_pos) or map_data[grid_pos].is_empty():
			print("⚠️ 建造拦截：只能在 Layer 0 上建造，这里是虚空！")
			return
			
		# 2. 探针：找出当前格子里已有的“最高层级”
		var highest_layer = -1
		for l in map_data[grid_pos].keys():
			if l > highest_layer:
				highest_layer = l
				
		# 3. 核心规则：只有当最高层刚好是 0 的时候，才允许施工！
		if highest_layer == 0:
			set_terrain(grid_pos, brush.id, true)
			print("✅ 建造模式成功：成功在 Layer 0 上铺设了 ", brush.id)
		else:
			# 如果最高层 > 0（比如已经是 1 了），说明上面已经有东西了，不让铺
			print("🚫 建造拦截：该区块上已经有其他地皮了！当前最高层为：", highest_layer)
			
	else:
		print("⚠️ 建造模式失败：手里拿的不是 TerrainData 画笔！")

func _process_delete_mode(grid_pos: Vector2i) -> void:
	if not map_data.has(grid_pos) or map_data[grid_pos].is_empty():
		print("⚠️ 拆除失败：目标格子没有任何地皮！")
		return
		
	var highest_layer = -1
	for l in map_data[grid_pos].keys():
		if l > highest_layer: highest_layer = l
			
	if highest_layer > 0:
		var target_id = map_data[grid_pos][highest_layer]
		set_terrain(grid_pos, target_id, false)
		print("⛏️ 成功铲除坐标 ", grid_pos, " 的层级 ", highest_layer)
	else:
		print("🛡️ 铲除拦截：目标是 Layer 0 地基，禁止破坏！")

# 增加静默参数 silent 避免初始生成时卡顿刷屏
func set_terrain(logic_cell: Vector2i, terrain_id: String, is_place: bool, silent: bool = false) -> void:
	if not terrain_config.has(terrain_id): 
		if not silent: print("⚠️ set_terrain 失败：未找到画笔 ID -> ", terrain_id)
		return
		
	var config = terrain_config[terrain_id]
	var layer = config.layer
	
	if is_place:
		# 🚨 重点排查区
		if layer > 0:
			if not map_data.has(logic_cell) or not map_data[logic_cell].has(0):
				if not silent: print("🚫 建造拦截：必须先铺设 Layer 0！你正在试图悬空建造 Layer ", layer)
				return
		
		if not map_data.has(logic_cell): map_data[logic_cell] = {}
		
		if map_data[logic_cell].has(layer) and map_data[logic_cell][layer] == terrain_id:
			return # 重复点击，静默返回
			
		map_data[logic_cell][layer] = terrain_id
		_update_visuals_around_logic_cell(logic_cell, layer)
		if not silent: print("✅ 成功放置！坐标: ", logic_cell, " ID: ", terrain_id, " 层级: ", layer)
		
	else:
		if layer == 0:
			if not silent: print("🚫 拆除拦截：这是 Layer 0 地基，代码强制保护。")
			return
			
		if not map_data.has(logic_cell) or not map_data[logic_cell].has(layer):
			return
			
		map_data[logic_cell].erase(layer)
		if map_data[logic_cell].is_empty():
			map_data.erase(logic_cell)
		_update_visuals_around_logic_cell(logic_cell, layer)

const VISUAL_OFFSETS = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

func _update_visuals_around_logic_cell(logic_cell: Vector2i, layer: int) -> void:
	for offset in VISUAL_OFFSETS:
		_refresh_single_visual_cell(logic_cell + offset, layer)

func _refresh_single_visual_cell(v_cell: Vector2i, layer: int) -> void:
	var target_tid = ""
	var check_offsets = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]
	
	for offset in check_offsets:
		var l_cell = v_cell + offset
		if map_data.has(l_cell) and map_data[l_cell].has(layer):
			target_tid = map_data[l_cell][layer]
			break 
			
	if target_tid == "":
		_delete_visual_node(v_cell, layer)
		return

	var top_left = 1 if _has_logic_terrain(v_cell - Vector2i(1, 1), layer, target_tid) else 0
	var top_right = 1 if _has_logic_terrain(v_cell - Vector2i(0, 1), layer, target_tid) else 0
	var bot_left = 1 if _has_logic_terrain(v_cell - Vector2i(1, 0), layer, target_tid) else 0
	var bot_right = 1 if _has_logic_terrain(v_cell - Vector2i(0, 0), layer, target_tid) else 0
	
	var state = [top_left, top_right, bot_left, bot_right]
	if state == [0, 0, 0, 0]:
		_delete_visual_node(v_cell, layer)
		return
		
	var atlas_coord = NEIGHBOUR_RULES[state]
	var region_rect = Rect2(atlas_coord.x * TILE_PIXEL_SIZE, atlas_coord.y * TILE_PIXEL_SIZE, TILE_PIXEL_SIZE, TILE_PIXEL_SIZE)
	
	if not map_nodes.has(v_cell): map_nodes[v_cell] = {}
	
	var config = terrain_config[target_tid]
	var existing_sprite = map_nodes[v_cell].get(layer)
	
	if existing_sprite != null and existing_sprite.texture != config.texture:
		existing_sprite.queue_free()
		existing_sprite = null
		
	if existing_sprite == null:
		existing_sprite = _create_sprite_3d(v_cell, config)
		map_nodes[v_cell][layer] = existing_sprite
		add_child(existing_sprite)
		
	existing_sprite.region_rect = region_rect

func _has_logic_terrain(cell: Vector2i, layer: int, target_tid: String) -> bool:
	return map_data.has(cell) and map_data[cell].has(layer) and map_data[cell][layer] == target_tid

func _delete_visual_node(v_cell: Vector2i, layer: int) -> void:
	if map_nodes.has(v_cell) and map_nodes[v_cell].has(layer):
		var node = map_nodes[v_cell][layer]
		if is_instance_valid(node): node.queue_free()
		map_nodes[v_cell].erase(layer)

func _create_sprite_3d(v_cell: Vector2i, config: Dictionary) -> Sprite3D:
	var sprite = Sprite3D.new()
	sprite.texture = config.texture
	sprite.region_enabled = true 
	sprite.axis = Vector3.AXIS_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD 
	sprite.alpha_scissor_threshold = 0.5
	sprite.render_priority = config.layer 
	
	if config.use_world_space and config.fill_texture != null:
		var mat = ShaderMaterial.new()
		mat.shader = preload("uid://i84s8hlc2fot")
		mat.set_shader_parameter("texture_albedo", config.texture)
		mat.set_shader_parameter("fill_texture", config.fill_texture)
		mat.set_shader_parameter("fill_scale", config.fill_scale)
		if config.border_texture != null:
			mat.set_shader_parameter("border_texture", config.border_texture)
		sprite.material_override = mat
	
	sprite.position = Vector3(v_cell.x * TILE_3D_SIZE, config.layer * Y_STEP, v_cell.y * TILE_3D_SIZE)
	var scale_factor = TILE_3D_SIZE / (TILE_PIXEL_SIZE * 0.01)
	sprite.scale = Vector3(scale_factor, scale_factor, scale_factor)
	return sprite

# 📞 对外通信接口：查询某个格子的最高层级
# ==========================================
func get_highest_layer(cell: Vector2i) -> int:
	if not map_data.has(cell) or map_data[cell].is_empty():
		return -1 # 返回 -1 代表这是虚空，连地基都没有
		
	var highest_layer = -1
	for l in map_data[cell].keys():
		if l > highest_layer:
			highest_layer = l
			
	return highest_layer
