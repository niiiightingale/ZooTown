extends Node

var grid_data: Dictionary = {}

func is_cell_occupied(cell: Vector2i, is_terrain: bool) -> bool:
	if is_terrain: return false 
	if grid_data.has(cell):
		var obj = grid_data[cell]["object"]
		# 🎯 验尸
		if obj != null and is_instance_valid(obj):
			return true
	return false

func register_item(covered_cells: Array[Vector2i], node: Node3D, is_terrain: bool) -> void:
	for cell in covered_cells:
		if not grid_data.has(cell):
			grid_data[cell] = { "terrain": null, "object": null }
		
		if is_terrain:
			var old = grid_data[cell]["terrain"]
			if old and is_instance_valid(old): old.queue_free()
			grid_data[cell]["terrain"] = node
		else:
			grid_data[cell]["object"] = node

func remove_items(cells: Array[Vector2i], is_terrain: bool) -> void:
	for cell in cells:
		if grid_data.has(cell):
			if is_terrain:
				grid_data[cell]["terrain"] = null
			else:
				grid_data[cell]["object"] = null

func get_node_at_cell(cell: Vector2i, check_terrain: bool = false) -> Node3D:
	if not grid_data.has(cell): return null
	var node = grid_data[cell]["terrain"] if check_terrain else grid_data[cell]["object"]
	
	# 🎯 验尸
	if is_instance_valid(node):
		return node
	else:
		# 自动清理脏数据
		if check_terrain: grid_data[cell]["terrain"] = null
		else: grid_data[cell]["object"] = null
		return null
