extends Area3D

@export var target_frequency: float = 80.0 # 目标频率
@export var tolerance: float = 10.0          # 容错范围
@export var zone_audio: AudioStream

# 用来记录当前在这个区域内的收音机节点
# 如果没有人或者没有收音机，它就是 null
var active_radio: Node = null

# --- 信号连接函数 ---

# 玩家进入区域时触发
func _on_body_entered(body: CharacterBody3D) -> void:
	# 尝试找收音机
	var radio = body.get_node_or_null("RadioSystem")
	if radio:
		active_radio = radio # 登记：当前有人拿着收音机进来了！
		print("进入信号区...")

# 玩家离开区域时触发
func _on_body_exited(body: CharacterBody3D) -> void:
	# 检查离开的人是不是当前拿着收音机的人
	var radio = body.get_node_or_null("RadioSystem")
	if radio == active_radio:
		active_radio = null # 注销：人走了，清空记录
		print("离开信号区。")

# --- 核心检测循环 ---

func _process(_delta: float) -> void:
	# 优化核心：只有当 active_radio 不为空（有人在里面）时，才运行检测代码！
	if active_radio:
		check_signal(active_radio)
		
		# 1. 计算差值
		var diff = abs(active_radio.current_frequency - target_frequency)
		
		# 2. 计算信号强度 (0.0 到 1.0)
		# 如果 diff > tolerance，强度为 0
		# 如果 diff = 0，强度为 1
		var strength = 0.0
		if diff < tolerance:
			# 这是一个归一化公式：越接近 0，值越接近 1
			strength = 1.0 - (diff / tolerance)
		
		# 3. 把强度传给收音机
		# 注意：我们需要在 RadioSystem 里加个接口来接收这个
		if active_radio.has_method("receive_signal"):
			active_radio.receive_signal(strength, zone_audio)

func check_signal(radio_node):
	# 访问 radio 脚本里的变量 current_frequency
	var diff = abs(radio_node.current_frequency - target_frequency)
	
	if diff < tolerance:
		print("接收到信号！滋滋滋...")
		# 在这里可以播放声音，或者显示字幕
	else:
		#print("错误")
		pass
