extends Node3D
class_name CameraRig 

# --- 配置 ---
@export_group("Follow Target")
@export var target: Node3D 
@export var follow_smoothness = 10.0

@export_group("Rotation Control")
@export var rotation_key_speed = 2.0
@export var mouse_sensitivity = 0.003 
@export var rotation_smoothness = 10.0 # 稍微调大一点，旋转更跟手

@export_group("Zoom Control")
@export var zoom_step = 8.0
@export var min_dist = 15.0
@export var max_dist = 300.0
@export var zoom_smoothness = 4.5

# --- 引用 ---
@onready var camera = $Camera3D 
@onready var virtual_cursor: CursorVisualizer = $CanvasLayer/VirtualCursor

# --- 内部状态 ---
var target_rotation_y = 0.0
var target_distance = 20.0
var cursor_pos = Vector2.ZERO 
var _is_rotating = false # 🎯 标记：是否正在右键旋转

# --- 接口 (给 PlacementManager 用) ---
func set_cursor_state(state: CursorVisualizer.CursorState) -> void:
	if virtual_cursor: virtual_cursor.set_state(state)

func get_cursor_screen_position() -> Vector2:
	return cursor_pos

func _ready():
	# 初始化旋转角度
	target_rotation_y = rotation.y
	
	# 初始化距离
	if camera:
		target_distance = camera.position.length()
	
	# 初始化鼠标模式
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cursor_pos = get_viewport().get_visible_rect().size / 2
	
	if virtual_cursor:
		virtual_cursor.position = cursor_pos
		virtual_cursor.set_state(CursorVisualizer.CursorState.NORMAL)

func _unhandled_input(event):
	# 1. ESC 解锁 / 点击锁定
	if event.is_action_pressed("ui_cancel"): 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if virtual_cursor: virtual_cursor.visible = false
		return 

	if event is InputEventMouseButton:
		# 点击重新锁定
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if virtual_cursor:
				virtual_cursor.visible = true
				cursor_pos = get_viewport().get_mouse_position()
				virtual_cursor.position = cursor_pos
		
		# 2. 滚轮缩放
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_distance -= zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_distance += zoom_step
			target_distance = clamp(target_distance, min_dist, max_dist)
			
		# 🎯 3. 右键旋转逻辑 (按下开始，松开停止)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rotating = event.pressed

	# 4. 鼠标移动处理
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			
			if _is_rotating:
				# === 模式 A: 正在旋转 ===
				# 只改角度，不改光标位置
				target_rotation_y -= event.relative.x * mouse_sensitivity
			else:
				# === 模式 B: 正常操作 ===
				# 只改光标位置
				cursor_pos += event.relative
				
				# 限制在屏幕内
				var screen_size = get_viewport().get_visible_rect().size
				cursor_pos.x = clamp(cursor_pos.x, 0, screen_size.x)
				cursor_pos.y = clamp(cursor_pos.y, 0, screen_size.y)
				
				if virtual_cursor:
					virtual_cursor.position = cursor_pos

func _physics_process(delta):
	# --- A. 处理位置跟随 (保留你的 Lerp 逻辑) ---
	if target:
		position = position.lerp(target.position, delta * follow_smoothness)
	
	# --- B. 应用旋转 (Lerp 插值让旋转有惯性) ---
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * rotation_smoothness)
	
	# --- C. 应用缩放 ---
	if camera:
		var direction = camera.position.normalized()
		var current_dist = camera.position.length()
		var new_dist = lerp(current_dist, target_distance, delta * zoom_smoothness)
		camera.position = direction * new_dist
