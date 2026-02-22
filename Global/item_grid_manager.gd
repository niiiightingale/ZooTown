extends Node

# 现在的字典极其干净：grid_data[Vector2i坐标] = Node3D实体节点
var grid_data: Dictionary = {}

func is_cell_occupied(cell: Vector2i) -> bool:
	if grid_data.has(cell):
		var obj = grid_data[cell]
		# 🎯 验尸：确认它不仅被记录了，而且还没被销毁
		if obj != null and is_instance_valid(obj):
			return true
		else:
			# 如果物体已经被拆除了（queue_free），顺手把坑位腾出来
			grid_data.erase(cell)
	return false

func register_item(covered_cells: Array[Vector2i], node: Node3D) -> void:
	for cell in covered_cells:
		# 直接把坐标指向这个实体节点，干脆利落
		grid_data[cell] = node

func remove_items(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if grid_data.has(cell):
			grid_data.erase(cell)

func get_node_at_cell(cell: Vector2i) -> Node3D:
	if grid_data.has(cell):
		var node = grid_data[cell]
		# 🎯 验尸
		if is_instance_valid(node):
			return node
		else:
			# 自动清理脏数据
			grid_data.erase(cell)
	return null
