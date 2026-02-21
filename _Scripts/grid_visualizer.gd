extends Node3D

const TILE_3D_SIZE = 4.0  # 必须和 TerrainManager 里的尺寸保持一致！
const GRID_RADIUS = 15    # 画多大范围（15代表前后左右各画15格）

func _ready() -> void:
	# 1. 🟥 逻辑网格 (红色 - 不变) 
	# 边界线在 0, 2, 4... 鼠标点击在 1,1 时会选中 (0,0) 这个红格子
	_draw_grid(Color(1, 0, 0, 0.5), Vector3(0, 0.01, 0))
	
	# 2. 🟩 视觉网格 (绿色 - 已修复)
	# 视觉层的中心点刚好骑在红色的十字交叉点上！
	# 所以它的网格边界线应该向右下偏移 0.5 个格子 (也就是 1.0 个单位)
	var offset = Vector3(0.5 * TILE_3D_SIZE, 0.02, 0.5 * TILE_3D_SIZE)
	_draw_grid(Color(0, 1, 0, 0.5), offset)

# ==========================================
# 📐 底层画线逻辑：用代码凭空生成网格线
# ==========================================
func _draw_grid(color: Color, offset: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	
	# 材质设置：无光照（纯色），半透明
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	mesh_instance.material_override = mat
	mesh_instance.mesh = immediate
	add_child(mesh_instance)
	
	# 开始绘制线条 (Mesh.PRIMITIVE_LINES 模式下，每两个顶点连成一条线)
	immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var max_dist = GRID_RADIUS * TILE_3D_SIZE
	for i in range(-GRID_RADIUS, GRID_RADIUS + 1):
		var pos = i * TILE_3D_SIZE
		
		# 画横线 (平行于 X 轴)
		immediate.surface_add_vertex(offset + Vector3(-max_dist, 0, pos))
		immediate.surface_add_vertex(offset + Vector3(max_dist, 0, pos))
		
		# 画竖线 (平行于 Z 轴)
		immediate.surface_add_vertex(offset + Vector3(pos, 0, -max_dist))
		immediate.surface_add_vertex(offset + Vector3(pos, 0, max_dist))
		
	immediate.surface_end()

# 💡 进阶联动：还记得你之前写的 Debug 模式开关吗？
# 如果你想按键切换网格的显示与隐藏，可以在这里加上：
# func _process(delta: float) -> void:
#     visible = GlobalDebug.is_debug_mode # 假设你做成了单例
