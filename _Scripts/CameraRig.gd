extends Node3D
class_name CameraRig 

# --- 配置 ---
@export_group("Follow Target")
@export var target: Node3D 
@export var follow_smoothness = 10.0

@export_group("Rotation Control")
@export var rotation_key_speed = 2.0
@export var mouse_sensitivity = 0.003 
@export var rotation_smoothness = 10.0

@export_group("Zoom Control")
@export var zoom_step = 8.0
@export var min_dist = 15.0
@export var max_dist = 300.0
@export var zoom_smoothness = 4.5

# --- 引用 ---
@onready var camera = $Camera3D 

# --- 内部状态 ---
var target_rotation_y = 0.0
var target_distance = 20.0
var _is_rotating = false 


func _ready():
	target_rotation_y = rotation.y
	if camera:
		target_distance = camera.position.length()
	
	# ✅ 【修复 1】 游戏刚加载时，主动请求锁定鼠标
	# 只有锁定了，你的 Input 逻辑才会开始跑
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event):
	# ✅ 【修复 2】 在“门卫”拦截之前，先给玩家一个“重新激活”的机会
	# 如果玩家点击了鼠标左键，说明他想回到游戏，立刻锁定鼠标
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			# 这里不要 return，继续向下执行，或者这一帧先 return 也行，下一帧就能动了

	# --- 原来的逻辑 ---
	# 如果经过上面的抢救，鼠标还是没锁定（说明玩家在切屏或者在菜单里），那才不处理
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_is_rotating = false 
		return

	if event is InputEventMouseButton:
		# 滚轮缩放
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_distance -= zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_distance += zoom_step
			target_distance = clamp(target_distance, min_dist, max_dist)
			
		# 右键旋转
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rotating = event.pressed

	# 鼠标移动处理
	if event is InputEventMouseMotion:
		if _is_rotating:
			# === 模式 A: 正在旋转 ===
			target_rotation_y -= event.relative.x * mouse_sensitivity

func _physics_process(delta):
	# 如果没有目标，就不跑逻辑
	if not target: return
	
	# --- A. 处理位置跟随 ---
	position = position.lerp(target.position, delta * follow_smoothness)
	
	# --- B. 应用旋转 ---
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * rotation_smoothness)
	
	# --- C. 应用缩放 ---
	if camera:
		var direction = camera.position.normalized()
		var current_dist = camera.position.length()
		var new_dist = lerp(current_dist, target_distance, delta * zoom_smoothness)
		camera.position = direction * new_dist
