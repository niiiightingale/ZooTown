extends Node
class_name DestructibleComponent

# 记录自己占用了哪些格子（世界坐标系下的绝对坐标，或者相对坐标）
# 为了方便，我们在 setup 时直接存下“去银行销户所需的绝对坐标列表”
var cells_to_clear: Array[Vector2i] = []
var is_terrain: bool = false

# === 初始化：记住自己的领地 ===
func setup(occupied_cells: Array[Vector2i], _is_terrain: bool) -> void:
	# occupied_cells 传入的是相对于物体中心的偏移量
	# 我们需要把它们转换成绝对坐标存下来，方便销户
	var origin = Vector2i(round(get_parent().global_position.x), round(get_parent().global_position.z))
	cells_to_clear.clear()
	for offset in occupied_cells:
		cells_to_clear.append(origin + offset)
	
	is_terrain = _is_terrain

# === 核心：上帝处决（立即消失） ===
func delete_instantly() -> void:
	# 1. 银行销户 (智能关联：一次性删掉所有占用的格子)
	WorldManager.remove_items(cells_to_clear, is_terrain)
	
	# 2. 物理毁灭
	get_parent().queue_free()

# === 扩展：玩家工具攻击（预留给未来游戏内互动） ===
func hit(_tool_type) -> void:
	# 这里以后写扣血逻辑
	print("物体挨打了！")
	pass
