extends Node

# 核心数据结构：存着所有摆放好的物件字典
# 格式: { "node": Node3D, "pos": Vector2, "radius": float }
var placed_items: Array[Dictionary] = []

# 🧮 核心数学魔法：圆心距离碰撞检测
func is_position_valid(target_pos_2d: Vector2, target_radius: float) -> bool:
	# 逆序遍历，边查边清理（自动“验尸”）
	for i in range(placed_items.size() - 1, -1, -1):
		var item = placed_items[i]
		
		# 🎯 验尸：如果这个实体被玩家删了，顺手把它从档案里除名
		if not is_instance_valid(item["node"]):
			placed_items.remove_at(i)
			continue
			
		# 📐 纯数学登场：两点之间的距离
		var distance = target_pos_2d.distance_to(item["pos"])
		
		# 如果两者圆心距离 < 两个半径之和，说明重合了！绝对不行！
		if distance < (target_radius + item["radius"]):
			return false
			
	return true

# 登记新物件
func register_item(node: Node3D, pos_2d: Vector2, radius: float) -> void:
	placed_items.append({
		"node": node,
		"pos": pos_2d,
		"radius": radius
	})
	
# 🗑️ 显式注销物件
# ==========================================
func remove_items(target_node: Node3D) -> void:
	# 倒序遍历数组，找到对应的节点直接踢掉
	for i in range(placed_items.size() - 1, -1, -1):
		var item = placed_items[i]
		if item["node"] == target_node:
			placed_items.remove_at(i)
			print("🗑️ [ItemManager] 成功注销实体！当前总数：", placed_items.size())
			break # 找到了就立刻跳出循环，节省性能
