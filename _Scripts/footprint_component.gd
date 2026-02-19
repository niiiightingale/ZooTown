@tool
extends Node3D
class_name FootprintComponent

@export_multiline var footprint_map: String = "O":
	set(value):
		footprint_map = value
		_parse_footprint()
		if Engine.is_editor_hint():
			_update_debug_meshes()

# ==========================================
# 🎯 核心修复：把格子大小暴露出来，并加上实时刷新！
# ==========================================
@export var cell_size: float = 0.5:
	set(value):
		cell_size = value
		if Engine.is_editor_hint():
			_update_debug_meshes()

var occupied_cells: Array[Vector2i] = []
var _debug_node: Node3D

func _ready() -> void:
	_parse_footprint()
	if Engine.is_editor_hint():
		_update_debug_meshes()
	else:
		# 游戏正式运行时，隐藏这些绿色的调试方块
		if _debug_node:
			_debug_node.hide()

func _parse_footprint() -> void:
	occupied_cells.clear()
	if footprint_map.is_empty():
		return
		
	var lines = footprint_map.split("\n")
	var origin_pos := Vector2i(-1, -1)
	
	# 第一遍：寻找你的基准原点 'O'
	for y in range(lines.size()):
		var line = lines[y] # 不去空格，保留真实的列位置
		var x_idx = line.find("O")
		if x_idx != -1:
			origin_pos = Vector2i(x_idx, y)
			break
			
	# 如果你在打字的过程中暂时删掉了 O，不报错，静默等待你打完
	if origin_pos == Vector2i(-1, -1):
		return
		
	# 第二遍：记录所有 'X' 和 'O' 相对于原点的坐标偏移
	for y in range(lines.size()):
		var line = lines[y]
		for x in range(line.length()):
			var char = line[x]
			if char == 'X' or char == 'O':
				var offset = Vector2i(x - origin_pos.x, y - origin_pos.y)
				occupied_cells.append(offset)


# 魔法视觉系统：在编辑器里实时生成半透明绿方块
# ==========================================
func _update_debug_meshes() -> void:
	if not is_inside_tree(): return
	
	# 🎯 核心防泄漏修复：直接去树上找有没有叫这个名字的节点！
	# 这样就算脚本重启、变量丢失，只要节点还在，就一定能被揪出来杀掉。
	var old_debug = get_node_or_null("DebugFootprint")
	if old_debug:
		old_debug.free() # 在 @tool 里用 free() 更干脆，避免名字冲突
		
	_debug_node = Node3D.new()
	_debug_node.name = "DebugFootprint"
	add_child(_debug_node)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.2, 0.5) 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(cell_size * 0.9, cell_size * 0.9) 
	
	for offset in occupied_cells:
		var mi = MeshInstance3D.new()
		mi.mesh = plane_mesh
		mi.material_override = mat
		mi.position = Vector3(offset.x * cell_size, 0.05, offset.y * cell_size)
		_debug_node.add_child(mi)
