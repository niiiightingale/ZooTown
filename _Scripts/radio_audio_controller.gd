extends Node

# 引用播放器
@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var signal_player: AudioStreamPlayer = $SignalPlayer

# 最小音量 (dB)，静音时的分贝数，通常 -60 到 -80
const MIN_DB: float = -80.0
# 最大音量 (dB)
const MAX_DB: float = 0.0

func _ready() -> void:
	# 初始状态：全是杂音，没有人声
	update_mix(0.0)
	
	# 确保杂音是循环播放的（需要在音频导入设置里把 Loop 勾上，或者这里强制 play）
	if not static_player.playing:
		static_player.play()
	if not signal_player.playing:
		signal_player.play()

# 核心函数：根据信号强度 (0.0 ~ 1.0) 调整音量
# strength = 1.0 (完美信号) -> 杂音静音，信号最大
# strength = 0.0 (完全没信号) -> 杂音最大，信号静音
func update_mix(strength: float) -> void:
	strength = clamp(strength, 0.0, 1.0)
	
	# 1. 计算杂音音量 (信号越强，杂音越弱)
	# linear_to_db 是 Godot 内置的神器，把 0-1 转换成分贝
	var static_vol = linear_to_db(1.0 - strength)
	static_player.volume_db = static_vol
	
	# 2. 计算信号音量
	var signal_vol = linear_to_db(strength)
	signal_player.volume_db = signal_vol

# 切换频道内容 (当进入不同区域时调用)
func set_channel_content(stream: AudioStream) -> void:
	# 关键修改：卫语句 (Guard Clause)
	# 如果当前播放器里装的已经是这个音频了，直接返回，不做任何操作
	if signal_player.stream == stream:
		# 只有一种情况需要处理：如果是同一个音频但意外停了，才重新播
		if not signal_player.playing:
			signal_player.play()
		return

	# --- 只有当音频文件发生变化时，才执行下面这些重置逻辑 ---
	
	signal_player.stream = stream
	signal_player.play()
	# 如果你想让切换频道时感觉更顺滑，不想重头开始播，可以尝试记录 playback_position
	# 但对于解谜游戏，通常重头播也没问题

# 停止所有声音 (收起收音机时)
func mute_all(is_muted: bool) -> void:
	# 使用 AudioServer 的 set_bus_mute 更专业，但这里简单的 stop/play 也可以
	if is_muted:
		static_player.stop()
		signal_player.stop()
	else:
		static_player.play()
		if signal_player.stream:
			signal_player.play()
