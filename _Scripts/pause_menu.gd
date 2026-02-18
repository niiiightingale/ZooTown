extends CanvasLayer

# --- 配置区 ---
# 这是一个开关，你可以在右侧检查器里随时勾选或取消
# 如果勾选，菜单打开时游戏世界会静止
@export var can_pause_game: bool = true 

var stored_cursor_state = 0
# --- 节点引用 ---
# 这是一个小技巧：以后如果你改了按钮名字，只需要在这里改路径
@onready var menu_container = $CenterContainer # 你的居中容器
@onready var resume_btn = $CenterContainer/MenuLayout/Btn_Continue
@onready var quit_btn = $CenterContainer/MenuLayout/Btn_Leave

func _ready():
	# 游戏开始时，先隐藏菜单
	hide_menu()
	
	# 连接按钮信号（这一步也可以在编辑器界面做，但在代码里写更保险）
	resume_btn.pressed.connect(_on_resume_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _input(event):
	# 监听 ESC 键 (Godot默认 ui_cancel 映射就是 ESC)
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide_menu() # 如果开着，就关掉
		else:
			show_menu() # 如果关着，就打开

func show_menu():
	# 1. 先获取当前【虚拟光标】在屏幕上的位置
	# (假设你的 GlobalCursor 脚本里有一个变量叫 screen_position 存着当前位置)
	var target_pos = GlobalCursor.screen_position
	
	# 2. 【核心修正】强行把【系统鼠标】搬运到这个位置去！
	# 这样解锁后，系统鼠标就会乖乖出现在虚拟光标所在的地方，不会乱跳
	Input.warp_mouse(target_pos)
	
	# 3. 存状态、改模式（原有逻辑）
	stored_cursor_state = GlobalCursor.current_state
	GlobalCursor.current_state = CursorVisualizer.CursorState.NORMAL
	
	show()
	
	# 4. 解锁鼠标 (HIDDEN 模式下，系统鼠标虽然看不见，但确实移动到了 target_pos)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN 
	get_tree().paused = true

func hide_menu():
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	
	# 3. 读档 (这就够了！Setter 会自动把锤子/删除图标换回来)
	GlobalCursor.current_state = stored_cursor_state
	
	if can_pause_game:
		get_tree().paused = false

# --- 按钮回调函数 ---

func _on_resume_pressed():
	# 点击“继续”等于关闭菜单
	hide_menu()

func _on_quit_pressed():
	# 点击“退出”，直接关闭程序
	get_tree().quit()
