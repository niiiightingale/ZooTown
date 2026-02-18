extends CanvasLayer

# --- 对外接口：让别人能获取鼠标位置 ---
var screen_position: Vector2 = Vector2.ZERO
var current_state: int = 0:
	set(new_value):
		if current_state == new_value:
			return
		# 1. 真正的赋值操作 (这一步必须写，否则变量永远不会变)
		current_state = new_value
		
		# 2. 自动触发刷新逻辑
		_update_visuals()
# --- 内部引用 ---
@onready var visuals = $VirtualCursor

# --- 配置 ---
@export var mouse_sensitivity = 1.0 # 如果你想在全局调整鼠标速度

func _ready():
	# 初始化位置在屏幕中心
	var viewport_size = get_viewport().get_visible_rect().size
	screen_position = viewport_size / 2
	update_visuals()
	
	# 初始锁定鼠标
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# 1. 只有当鼠标被“捕获”时，我们才手动计算位置
	# (对应游戏进行中)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			screen_position += event.relative * mouse_sensitivity
			clamp_screen_position()
			update_visuals()

	# 2. 如果鼠标是“隐藏/可见”的 (对应暂停菜单/UI模式)
	# 我们直接跟随系统鼠标，不需要计算 relative
	elif Input.mouse_mode == Input.MOUSE_MODE_HIDDEN: 
		if event is InputEventMouseMotion:
			screen_position = event.position
			update_visuals()

func clamp_screen_position():
	var viewport_rect = get_viewport().get_visible_rect()
	screen_position.x = clamp(screen_position.x, 0, viewport_rect.size.x)
	screen_position.y = clamp(screen_position.y, 0, viewport_rect.size.y)

func update_visuals():
	if visuals:
		visuals.position = screen_position

# --- 供外部调用的功能 ---

# 改变鼠标样子 (Normal, Build, Delete)
func set_cursor_state(state):
	# 【新增 2】每次改变状态时，记录下来
	current_state = state
	if visuals:
		visuals.set_state(state)

# 获取鼠标当前在哪 (给射线检测用)
func get_cursor_position() -> Vector2:
	return screen_position
	
func get_current_state():
	return current_state
	
# --- 内部刷新函数 ---
func _update_visuals():
	# 防空判断
	if visuals:
		visuals.set_state(current_state)
		print("GlobalCursor: 状态已自动更新为 -> ", current_state)
