extends Node
class_name DestructibleComponent

enum ToolType { NONE, HAMMER, PITCHFORK }

@export_group("Destruction Settings")
@export var required_tool: ToolType = ToolType.HAMMER 
@export var hits_to_destroy: int = 1                  

var current_hits: int = 0

# ❌ 删掉了原本 setup 里的 occupied_cells 和 is_terrain，因为现在完全不需要了！
func setup() -> void:
	pass # 如果未来需要初始化血量，可以写在这里

# 地图编辑器调用 (一击必杀)
func delete_instantly() -> void:
	destroy()

# 游戏内工具调用 (正常扣血)
func hit(tool: ToolType) -> void:
	if tool != required_tool and required_tool != ToolType.NONE:
		print("工具不对！无法拆除。")
		return
		
	current_hits += 1
	
	# 受击微动画
	var tween = create_tween()
	var parent = get_parent()
	tween.tween_property(parent, "scale", Vector3(1.1, 0.9, 1.1), 0.05)
	tween.tween_property(parent, "scale", Vector3.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	if current_hits >= hits_to_destroy:
		destroy()

# === 💀 死亡逻辑与后事处理 ===
func destroy() -> void:
	var parent = get_parent()
	
	# 1. 📋 去户籍科注销户口 (最优先执行，确保逻辑立刻畅通)
	# 把父节点(也就是这棵树/建筑)的引用传过去注销
	if ItemGridManager.has_method("remove_items"):
		ItemGridManager.remove_items(parent)
		print("✅ 物体户口已注销，圆圈范围已腾空！")
	
	# 2. 🎁 生成掉落物 (未来在这里写)
	# spawn_drops()
	
	# 3. 🎬 移交动画权或直接火化
	var tween_comp = parent.get_node_or_null("TweenComponent")
	if tween_comp:
		# 让动画组件接管，播完动画后由它负责 queue_free
		tween_comp.play_death()
	else:
		# 没有动画，直接当场去世
		parent.queue_free()
