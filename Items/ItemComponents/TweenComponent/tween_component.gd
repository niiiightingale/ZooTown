extends Node
class_name TweenComponent

@export_group("Birth Settings")
@export var birth_duration: float = 0.5
@export var birth_transition: Tween.TransitionType = Tween.TRANS_ELASTIC
@export var birth_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Death Settings")
@export var death_duration: float = 0.25
@export var death_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var death_ease: Tween.EaseType = Tween.EASE_IN

func _ready() -> void:
	# 确保父节点存在
	var parent = get_parent()
	if not parent: return
	
	# 1. 初始状态：设为极小 (0.01 比 0 安全，防止某些物理计算除以零报错)
	parent.scale = Vector3(0.01, 0.01, 0.01)
	
	# 2. 播放出生动画 (Duang~ 地弹出来)
	var tween = create_tween()
	tween.tween_property(parent, "scale", Vector3.ONE, birth_duration)\
		.set_trans(birth_transition)\
		.set_ease(birth_ease)

# === 对外接口：播放死亡动画并销毁 ===
func play_death() -> void:
	var parent = get_parent()
	if not parent: return
	
	# 1. 播放死亡动画 (咻~ 地缩回去)
	var tween = create_tween()
	tween.tween_property(parent, "scale", Vector3(0.01, 0.01, 0.01), death_duration)\
		.set_trans(death_transition)\
		.set_ease(death_ease)
	
	# 2. 🎯 关键：动画结束后，执行真正的物理销毁
	tween.finished.connect(func(): parent.queue_free())
