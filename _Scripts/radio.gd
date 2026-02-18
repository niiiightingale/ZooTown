extends Node
class_name RadioSystem

# --- 引用 UI ---
# 把 CanvasLayer 下那个 RadioContainer 拖进来
@export var ui_container: Control 
# 把显示数字的 Label 拖进来
@export var freq_label: Label 
@export var default_frequency:float = 50.0
@export var audio_controller:Node

# --- 基础参数 ---
var current_frequency: float = 0.0
var min_freq: float = 0.0
var max_freq: float = 99.9
var tune_speed: float = 10.0

# --- 动画与状态 ---
var is_radio_open: bool = false # 记录当前是开还是关
var show_position: Vector2      # 显示时的坐标
var hide_position: Vector2      # 隐藏时的坐标 (比如屏幕外面)

# 新增变量：记录上一帧是否有信号输入，如果一帧没收到信号，说明在荒野
var has_signal_input: bool = false

func _ready() -> void:
	
	current_frequency = default_frequency
	# 1. 初始化位置记录
	if ui_container:
		# 记录当前你在编辑器里摆好的位置作为 "显示位置"
		show_position = ui_container.position
		
		# 计算 "隐藏位置"：在显示位置的基础上，往下移动 300 像素 (或者更多，取决于你图片多高)
		hide_position = show_position + Vector2(0, 500)
		
		# 游戏开始时，先把收音机藏起来
		ui_container.position = hide_position
		audio_controller.mute_all(not is_radio_open)
		is_radio_open = false
		
	# 更新一次文字
	update_ui_text()

func _input(event: InputEvent) -> void:
	# 2. 检测 F 键 (toggle_radio)
	if event.is_action_pressed("toggle_radio"):
		toggle_animation()

func _process(delta: float) -> void:
	# 3. 只有收音机打开时 (is_radio_open 为 true)，才允许调频！
	if is_radio_open:
		var input_axis = Input.get_axis("rotate_left", "rotate_right") # 假设你用上下键调频
		
		if input_axis != 0:
			current_frequency += input_axis * tune_speed * delta
			current_frequency = clamp(current_frequency, min_freq, max_freq)
			update_ui_text()
			
	#重置信号状态
	has_signal_input = false

# --- 核心功能：Tween 动画 ---
func toggle_animation() -> void:
	# 如果 UI 没赋值，防报错
	if not ui_container: return

	# 切换开关状态
	is_radio_open = not is_radio_open
	
	# 创建 Tween (Godot 4 写法非常简洁)
	var tween = create_tween()
	
	# 设置动画曲线 (TransBack 会有一种 Q 弹的感觉，EaseOut 让他减速停下)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if is_radio_open:
		# 如果变成了开，就移动到 show_position
		# 0.5 是动画时间 (秒)
		tween.tween_property(ui_container, "position", show_position, 0.5)
		print("拿出收音机")
	else:
		# 如果变成了关，就用 EASE_IN 加速移出去
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(ui_container, "position", hide_position, 0.5)
		print("收起收音机")
		
	if audio_controller:
		# 如果是关，就静音；如果是开，就恢复
		audio_controller.mute_all(not is_radio_open)
		print("音乐打开/关闭")

func update_ui_text() -> void:
	if freq_label:
		# 保留1位小数
		freq_label.text = "%.1f" % current_frequency

# 新增：供 SignalZone 调用的接口
func receive_signal(strength: float, clip: AudioStream) -> void:
	has_signal_input = true
	
	if is_radio_open and audio_controller:
		# 1. 告诉音频控制器播放什么
		#audio_controller.set_channel_content(clip)
		# 2. 告诉音频控制器现在的混合比例
		audio_controller.update_mix(strength)

# 检查：如果这一帧没人调用 receive_signal，说明完全没信号
func _physics_process(_delta: float) -> void:
	if is_radio_open and not has_signal_input and audio_controller:
		# 也就是强度为 0，全是杂音
		audio_controller.update_mix(0.0)
