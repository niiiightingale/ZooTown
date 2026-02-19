extends CanvasLayer

@export var can_pause_game: bool = true 
var stored_cursor_state = 0 

@onready var menu_container = $CenterContainer
@onready var resume_btn = $CenterContainer/MenuLayout/Btn_Continue
@onready var quit_btn = $CenterContainer/MenuLayout/Btn_Leave

func _ready():
	hide()
	resume_btn.bouncy_pressed.connect(_on_resume_pressed)
	quit_btn.bouncy_pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide_menu()
		else:
			show_menu()

func show_menu():
	# 1. 存盘并切回普通鼠标
	stored_cursor_state = GlobalCursor.current_state
	GlobalCursor.current_state = CursorVisualizer.CursorState.NORMAL
	
	show()
	
	# 2. 直接暂停（不需要任何鼠标模式的切换代码了！）
	if can_pause_game:
		get_tree().paused = true
	GlobalCursor.free_cursor()

func hide_menu():
	hide()
	
	# 1. 恢复游戏
	if can_pause_game:
		get_tree().paused = false
		
	# 2. 读档，恢复建造/删除图标
	GlobalCursor.current_state = stored_cursor_state
	GlobalCursor.lock_cursor()

func _on_resume_pressed():
	hide_menu()

func _on_quit_pressed():
	get_tree().quit()
