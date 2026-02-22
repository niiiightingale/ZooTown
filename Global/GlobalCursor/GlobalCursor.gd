extends CanvasLayer

@export var visualCursor: CursorVisualizer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
	# 🌟 核心对接：订阅总司令部的频道
	GameState.mode_changed.connect(_on_global_mode_changed)
	
	# 初始化：进游戏先对齐一次当前状态
	_on_global_mode_changed(GameState.current_mode)

func _process(_delta):
	# 🌟 核心变化：每一帧，手绘光标直接飞到系统鼠标的位置 (保持你原来的完美代码)
	if visualCursor:
		visualCursor.global_position = get_viewport().get_mouse_position()

# 🎯 只要 GameState 一变，这里就会自动触发！外面谁都不用管！
func _on_global_mode_changed(new_mode: GameState.Mode) -> void:
	if visualCursor:
		visualCursor.set_state(new_mode)
		print("✅ [全局光标] 贴图已自动同步至 GameState 新模式 -> ", new_mode)

# 保留你原本用来处理窗口/UI交互的解锁逻辑
func free_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func lock_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
