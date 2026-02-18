extends Node3D
class_name CameraRig # 建议加上类名，方便其他脚本引用

# --- 配置 ---
@export_group("Follow Target")
@export var target: Node3D 
@export var follow_smoothness = 10.0

@export_group("Zoom Control")
@export var zoom_step = 8.0
@export var min_dist = 15.0
@export var max_dist = 300.0
@export var zoom_smoothness = 4.5

# --- 引用 ---
@onready var camera = $Camera3D 
# [修改] 这里会自动识别我们刚才写的那个脚本，拥有代码提示
@onready var virtual_cursor: CursorVisualizer = $CanvasLayer/VirtualCursor

# --- 内部状态 ---
var target_distance = 20.0
var cursor_pos = Vector2.ZERO 
var _mouse_accum: Vector2 = Vector2.ZERO

# [新增] 对外接口：让其他脚本（如 PlacementManager）调用这个来换鼠标
func set_cursor_state(state: CursorVisualizer.CursorState) -> void:
	if virtual_cursor:
		virtual_cursor.set_state(state)

# [新增] 对外接口：获取当前屏幕光标位置（射线检测需要用到）
func get_cursor_screen_position() -> Vector2:
	return cursor_pos

func _ready():
	if camera:
		target_distance = camera.position.length()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 初始化位置到屏幕中心
	cursor_pos = get_viewport().get_visible_rect().size / 2
	if virtual_cursor:
		virtual_cursor.position = cursor_pos
		# 默认设为普通状态
		virtual_cursor.set_state(CursorVisualizer.CursorState.NORMAL)

func _process(_delta: float) -> void:
	# --- 这里的逻辑和你原先写的一模一样，不用动！ ---
	if _mouse_accum != Vector2.ZERO:
		cursor_pos += _mouse_accum
		
		var screen_size = get_viewport().get_visible_rect().size
		cursor_pos.x = clamp(cursor_pos.x, 0, screen_size.x)
		cursor_pos.y = clamp(cursor_pos.y, 0, screen_size.y)
		
		if virtual_cursor:
			virtual_cursor.position = cursor_pos
		
		_mouse_accum = Vector2.ZERO

func _unhandled_input(event):
	# --- 原有逻辑保留 ---
	if event.is_action_pressed("ui_cancel"): 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if virtual_cursor: virtual_cursor.visible = false
		return 

	if event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if virtual_cursor:
				virtual_cursor.visible = true
				cursor_pos = get_viewport().get_mouse_position()
				virtual_cursor.position = cursor_pos
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_distance -= zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_distance += zoom_step
			target_distance = clamp(target_distance, min_dist, max_dist)
	
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_accum += event.relative

func _physics_process(delta):
	# --- 原有逻辑保留 ---
	if target:
		position = position.lerp(target.position, delta * follow_smoothness)
	
	if camera:
		var direction = camera.position.normalized()
		var current_dist = camera.position.length()
		var new_dist = lerp(current_dist, target_distance, delta * zoom_smoothness)
		camera.position = direction * new_dist
