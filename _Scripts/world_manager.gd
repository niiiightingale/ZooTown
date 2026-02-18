extends Node

# 这是我们全新的、脱离了具体场景的“世界双层账本”
var grid_data: Dictionary = {}

# === 核心接口 1：查询网格是否被占用 ===
func is_cell_occupied(cell: Vector2i, is_terrain: bool) -> bool:
	if is_terrain: 
		return false # 地皮拥有绝对覆盖权，永远视为未占用
	
	# 🎯 增加防崩溃检查：如果记录里的物体已经死透了，视为未占用
	if grid_data.has(cell):
		var obj = grid_data[cell]["object"]
		if obj != null and is_instance_valid(obj):
			return true
		
	return false

# === 核心接口 2：向账本登记新建筑/地形 ===
func register_item(covered_cells: Array[Vector2i], node: Node3D, is_terrain: bool) -> void:
	for cell in covered_cells:
		# 确保格子存在
		if not grid_data.has(cell):
			grid_data[cell] = { "terrain": null, "object": null }
		
		# 写入数据 & 物理销毁旧地形
		if is_terrain:
			var old_terrain = grid_data[cell]["terrain"]
			if old_terrain != null and is_instance_valid(old_terrain):
				old_terrain.queue_free() # 杀掉旧地皮
			grid_data[cell]["terrain"] = node
		else:
			grid_data[cell]["object"] = node

# === 核心接口 3：销毁清理（销户） ===
func remove_items(cells: Array[Vector2i], is_terrain: bool) -> void:
	for cell in cells:
		if grid_data.has(cell):
			if is_terrain:
				grid_data[cell]["terrain"] = null
			else:
				grid_data[cell]["object"] = null
			# 注：我们保留了 { "terrain": null, "object": null } 结构，不直接 erase，防止字典结构破坏

# === 核心接口 4：精准抓取格子上的物体（雷达索敌） ===
# 🎯 修复版：增加了 is_instance_valid 检查，防止返回已删除的“僵尸”物体
func get_node_at_cell(cell: Vector2i, check_terrain: bool = false) -> Node3D:
	if not grid_data.has(cell):
		return null
		
	var node = null
	
	if check_terrain:
		node = grid_data[cell]["terrain"]
	else:
		node = grid_data[cell]["object"]
	
	# ==========================================
	# 🎯 核心修复：必须检查这个节点是否还“活着”！
	# ==========================================
	if is_instance_valid(node):
		return node
	else:
		# 既然发现这是个“死人”，顺手把这笔脏账清理掉，防止下次再报错
		if check_terrain:
			grid_data[cell]["terrain"] = null
		else:
			grid_data[cell]["object"] = null
		return null
