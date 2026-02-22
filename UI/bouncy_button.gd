extends TextureButton
class_name BouncyButton

# 🌟 自定义一个新信号，用来代替原来的 pressed
signal bouncy_pressed

# --- 配置动画参数 ---
var hover_scale := Vector2(1.1, 1.1)   # 悬停时稍微变大
var press_scale := Vector2(0.85, 0.85) # 按下时被“挤扁”
var normal_scale := Vector2(1.0, 1.0)  # 默认大小

var _is_animating := false
var _tween: Tween

func _ready() -> void:
	# 🎯 解决暗坑1：自动把缩放中心设置到按钮正中心
	# 这样就算你以后在编辑器里随便改按钮大小，它永远从中心缩放，不会长歪！
	pivot_offset = size / 2.0
	
	# 绑定原生鼠标事件
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_click)

func _on_hover() -> void:
	if _is_animating or disabled: return
	# 悬停时：用 TRANS_BACK 做出稍微超出一点再缩回来的吸附感
	_animate_scale(hover_scale, 0.25, Tween.TRANS_BACK)

func _on_unhover() -> void:
	if _is_animating or disabled: return
	_animate_scale(normal_scale, 0.2, Tween.TRANS_SINE)

func _on_click() -> void:
	if _is_animating: return
	
	# 🎯 解决暗坑3：防连点锁。动画期间不接受任何新点击
	_is_animating = true 
	
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	
	# 🌟 Q弹灵魂核心！分为两段动画 🌟
	# 第一段：0.1秒内迅速下压（被手指用力按扁）
	_tween.tween_property(self, "scale", press_scale, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 第二段：0.35秒内弹回原状（TRANS_ELASTIC 就是那个充满肉感的果冻回弹材质！）
	_tween.tween_property(self, "scale", normal_scale, 0.05).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# 🎯 解决暗坑4：等待动画彻底播完
	await _tween.finished
	
	_is_animating = false
	
	# 动画结束，正式发送你的专属点击信号！
	bouncy_pressed.emit()

func _animate_scale(target: Vector2, duration: float, trans_type: Tween.TransitionType) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", target, duration).set_trans(trans_type).set_ease(Tween.EASE_OUT)
