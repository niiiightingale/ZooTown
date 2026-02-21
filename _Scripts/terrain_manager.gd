extends Node
class_name TerrainManager

# ==========================================
# ⚙️ 核心参数与层级配置
# ==========================================
const TILE_PIXEL_SIZE = 128
const TILE_3D_SIZE = 2.0 
# 每层物理高度只抬升 2 毫米，配合 render_priority 杜绝深度闪烁
const Y_STEP = 0.002 

@export var terrain_resources: Array[TerrainData]

# ==========================================
# 🗺️ 16 宫格状态映射表 (纯正的双网格核心)
# ==========================================
# 顺序: [左上, 右上, 左下, 右下]
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

# ==========================================
# 🗂️ 核心数据结构 (三维嵌套字典)
# ==========================================
# 逻辑数据字典：map_data[逻辑坐标 Vector2i][层级 int] = "terrain_id"
var map_data: Dictionary = {}

# 视觉节点字典：map_nodes[视觉坐标 Vector2i][层级 int] = Sprite3D节点
# 🚨 (在双网格中，视觉节点的坐标是在逻辑格子的交界处！)
var map_nodes: Dictionary = {}

var terrain_config: Dictionary = {}

func _ready() -> void:
	for res in terrain_resources:
		if res == null: continue
		terrain_config[res.id] = {
			"layer": res.layer,
			"texture": res.texture,
			"sound": res.place_sound,
			"use_world_space": res.use_world_space_texture,
			"fill_texture": res.fill_texture,
			"fill_scale": res.fill_scale,
			"border_texture": res.border_texture
		}

# ==========================================
# 🖱️ 鼠标交互状态测试工具
# ==========================================
var last_painted_cell: Vector2i = Vector2i(-99999, -99999)

# 🎯 请在这里填入你基础地皮 (Layer 0) 的 ID 进行初步测试
var current_brush: String = "ground" 

func _unhandled_input(event: InputEvent) -> void:
	var is_click = event is InputEventMouseButton and event.pressed
	var is_drag = event is InputEventMouseMotion
	
	if not (is_click or is_drag): 
		if event is InputEventMouseButton and not event.pressed:
			last_painted_cell = Vector2i(-99999, -99999)
		return

	var is_placing = false
	var is_deleting = false
	
	if is_click:
		is_placing = event.button_index == MOUSE_BUTTON_LEFT
		is_deleting = event.button_index == MOUSE_BUTTON_RIGHT
	elif is_drag:
		is_placing = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		is_deleting = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		
	if not is_placing and not is_deleting:
		return

	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
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
		
		if is_placing:
			set_terrain(grid_pos, current_brush, true)
		elif is_deleting:
			set_terrain(grid_pos, current_brush, false)

func _world_to_grid(hit_position: Vector3) -> Vector2i:
	var grid_x = floor(hit_position.x / TILE_3D_SIZE)
	var grid_z = floor(hit_position.z / TILE_3D_SIZE)
	return Vector2i(grid_x, grid_z)

# ==========================================
# 🎮 放置与拆除逻辑 (多层级架构)
# ==========================================
func set_terrain(logic_cell: Vector2i, terrain_id: String, is_place: bool) -> void:
	if not terrain_config.has(terrain_id): 
		print("⚠️ 找不到画笔 ID: ", terrain_id)
		return
		
	var config = terrain_config[terrain_id]
	var layer = config.layer
	
	if is_place:
		# 🚨 防护墙：除了第 0 层，其他地皮必须建在 0 层之上
		if layer > 0:
			if not map_data.has(logic_cell) or not map_data[logic_cell].has(0):
				print("⚠️ 不能在虚空建造！必须先铺设默认地皮(Layer 0)。")
				return
		
		if not map_data.has(logic_cell): map_data[logic_cell] = {}
		
		# 防重复点击
		if map_data[logic_cell].has(layer) and map_data[logic_cell][layer] == terrain_id:
			return
			
		# 更新数据
		map_data[logic_cell][layer] = terrain_id
		
		# 触发双网格视觉更新
		_update_visuals_around_logic_cell(logic_cell, layer)
		
	else: # 拆除
		if not map_data.has(logic_cell) or not map_data[logic_cell].has(layer):
			return
			
		# 🚨 连锅端逻辑：抽走底层，上层全部塌陷
		if layer == 0:
			var layers_to_remove = map_data[logic_cell].keys().duplicate()
			map_data.erase(logic_cell) # 先清空数据
			for l in layers_to_remove:
				_update_visuals_around_logic_cell(logic_cell, l)
			return 
		else:
			map_data[logic_cell].erase(layer)
			if map_data[logic_cell].is_empty():
				map_data.erase(logic_cell)
			_update_visuals_around_logic_cell(logic_cell, layer)

# ==========================================
# 🧩 双网格视觉刷新核心 (Dual-Grid)
# ==========================================
# 改变 1 个逻辑格子，会影响它右下角这 4 个视觉交界处
const VISUAL_OFFSETS = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

func _update_visuals_around_logic_cell(logic_cell: Vector2i, layer: int) -> void:
	for offset in VISUAL_OFFSETS:
		var visual_cell = logic_cell + offset
		_refresh_single_visual_cell(visual_cell, layer)

func _refresh_single_visual_cell(v_cell: Vector2i, layer: int) -> void:
	# 1. 扫描周围 4 个逻辑格子，找出当前视觉交界处应该显示哪种地形
	var target_tid = ""
	var check_offsets = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]
	
	for offset in check_offsets:
		var l_cell = v_cell + offset
		if map_data.has(l_cell) and map_data[l_cell].has(layer):
			target_tid = map_data[l_cell][layer]
			break 
			
	# 如果周围全空了，直接删除这个视觉节点
	if target_tid == "":
		_delete_visual_node(v_cell, layer)
		return

	# 2. 查验 4 个逻辑角落的状态
	var top_left = 1 if _has_logic_terrain(v_cell - Vector2i(1, 1), layer, target_tid) else 0
	var top_right = 1 if _has_logic_terrain(v_cell - Vector2i(0, 1), layer, target_tid) else 0
	var bot_left = 1 if _has_logic_terrain(v_cell - Vector2i(1, 0), layer, target_tid) else 0
	var bot_right = 1 if _has_logic_terrain(v_cell - Vector2i(0, 0), layer, target_tid) else 0
	
	var state = [top_left, top_right, bot_left, bot_right]
	
	# 万一算出全空（理论上上面拦截了），也删掉节点
	if state == [0, 0, 0, 0]:
		_delete_visual_node(v_cell, layer)
		return
		
	# 3. 计算图集切片
	var atlas_coord = NEIGHBOUR_RULES[state]
	var region_rect = Rect2(atlas_coord.x * TILE_PIXEL_SIZE, atlas_coord.y * TILE_PIXEL_SIZE, TILE_PIXEL_SIZE, TILE_PIXEL_SIZE)
	
	# 4. 生成或更新 Sprite3D
	if not map_nodes.has(v_cell): map_nodes[v_cell] = {}
	
	var config = terrain_config[target_tid]
	var existing_sprite = map_nodes[v_cell].get(layer)
	
	# 🚨 安全机制：如果原本有节点，但是材质不一样(比如在这层用砖块替换了木板)，删掉重建
	if existing_sprite != null and existing_sprite.texture != config.texture:
		existing_sprite.queue_free()
		existing_sprite = null
		
	if existing_sprite == null:
		existing_sprite = _create_sprite_3d(v_cell, config)
		map_nodes[v_cell][layer] = existing_sprite
		add_child(existing_sprite)
		
	# 刷新最终图像
	existing_sprite.region_rect = region_rect

# 辅助判定函数
func _has_logic_terrain(cell: Vector2i, layer: int, target_tid: String) -> bool:
	return map_data.has(cell) and map_data[cell].has(layer) and map_data[cell][layer] == target_tid

func _delete_visual_node(v_cell: Vector2i, layer: int) -> void:
	if map_nodes.has(v_cell) and map_nodes[v_cell].has(layer):
		var node = map_nodes[v_cell][layer]
		if is_instance_valid(node):
			node.queue_free()
		map_nodes[v_cell].erase(layer)

# ==========================================
# 🧱 生成 3D 纸片与遮罩材质
# ==========================================
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
		# 🎯 请确保这里指向你正确的 shader 文件名！
		mat.shader = preload("uid://i84s8hlc2fot")
		mat.set_shader_parameter("texture_albedo", config.texture)
		mat.set_shader_parameter("fill_texture", config.fill_texture)
		mat.set_shader_parameter("fill_scale", config.fill_scale)
		if config.border_texture != null:
			mat.set_shader_parameter("border_texture", config.border_texture)
		sprite.material_override = mat
	
	var offset_x = v_cell.x * TILE_3D_SIZE
	var offset_z = v_cell.y * TILE_3D_SIZE
	var y_pos = config.layer * Y_STEP 
	
	sprite.position = Vector3(offset_x, y_pos, offset_z)
	var scale_factor = TILE_3D_SIZE / (TILE_PIXEL_SIZE * 0.01)
	sprite.scale = Vector3(scale_factor, scale_factor, scale_factor)
	return sprite
