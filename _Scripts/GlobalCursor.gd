extends CanvasLayer

@export var visualCursor:CursorVisualizer

# 优雅的状态管理器
var current_state: int = 0:
	set(new_value):
		if current_state == new_value:
			return
		current_state = new_value
		_update_visuals()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	

func _process(_delta):
	# 🌟 核心变化：每一帧，手绘光标直接飞到系统鼠标的位置
	# 因为系统鼠标全程都在正常工作（只是隐身了），所以这么写最准，且永远不会跳变
	if visualCursor:
		visualCursor.global_position = get_viewport().get_mouse_position()

func _update_visuals():
	if visualCursor:
		visualCursor.set_state(current_state)
		print("✅ [全局光标] 贴图已切换，当前状态枚举值 -> ", current_state)
		
func set_cursor_state(state):
	# 【新增 2】每次改变状态时，记录下来
	current_state = state
	if visualCursor:
		visualCursor.set_state(state)
		
func free_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
func lock_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
