extends Node
class_name DestructibleComponent

enum ToolType { NONE, HAMMER, PITCHFORK }

@export_group("Destruction Settings")
@export var required_tool: ToolType = ToolType.HAMMER 
@export var hits_to_destroy: int = 1                  
@export var is_terrain: bool = false                  

var current_hits: int = 0
var occupied_cells: Array[Vector2i] = [] 

func setup(cells: Array[Vector2i], _is_terrain: bool = false) -> void:
	occupied_cells = cells.duplicate()
	is_terrain = _is_terrain

# 地图编辑器调用
func delete_instantly() -> void:
	destroy()

# 游戏内工具调用
func hit(tool: ToolType) -> void:
	if tool != required_tool and required_tool != ToolType.NONE:
		print("工具不对！无法拆除。")
		return
		
	current_hits += 1
	
	# 受击微动画 (简单的挤压反馈)
	var tween = create_tween()
	var parent = get_parent()
	# 先压扁一点点
	tween.tween_property(parent, "scale", Vector3(1.1, 0.9, 1.1), 0.05)
	# 再弹回原状
	tween.tween_property(parent, "scale", Vector3.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	if current_hits >= hits_to_destroy:
		destroy()

# === 💀 死亡逻辑 ===
func destroy() -> void:
	# 1. 先去银行销户 (这步必须立刻做，防止逻辑上还没死透)
	WorldManager.remove_items(occupied_cells, is_terrain)
	print("物体被拆除，格子已腾空！")
	
	# 2. 寻找负责丧葬的同事 (TweenComponent)
	# 假设它们都是根节点的直接子节点，所以是“兄弟关系”
	var tween_comp = get_parent().get_node_or_null("TweenComponent")
	
	if tween_comp:
		# 🎯 有动画组件：把“物理销毁”的权力移交给它
		tween_comp.play_death()
	else:
		# 🎯 没有动画组件：直接暴毙 (保底逻辑)
		get_parent().queue_free()
