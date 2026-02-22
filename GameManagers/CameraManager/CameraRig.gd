extends Node3D
class_name CameraRig 

@export_group("Follow Target")
@export var target: Node3D 
@export var follow_smoothness = 10.0
# 🌟 新增：瞄准偏移量！设为 1.0 左右，摄像机会盯住角色的胸口/头部
@export var target_offset_y: float = 1.5 

@export_group("Zoom & Pitch Control")
@export var zoom_step = 8.0
@export var min_dist = 15.0
@export var max_dist = 300.0
@export var zoom_smoothness = 4.5
@export var min_pitch: float = -15.0 
@export var max_pitch: float = -65.0 

@export_group("Rotation Control")
@export var rotation_step: float = 45.0
@export var rotation_smoothness: float = 8.0

@onready var camera = $Camera3D 

var target_distance = 20.0
var target_rotation_y: float = 0.0

func _ready():
	if camera:
		target_distance = camera.position.length()
	target_rotation_y = rotation.y

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_distance -= zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_distance += zoom_step
			target_distance = clamp(target_distance, min_dist, max_dist)
			
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			target_rotation_y += deg_to_rad(rotation_step)
		elif event.keycode == KEY_E:
			target_rotation_y -= deg_to_rad(rotation_step)

func _physics_process(delta):
	if not target: return
	
	# A. 🌟 改进跟随：计算加上垂直偏移量后的“真正目标点”
	var actual_target_pos = target.position + Vector3(0, target_offset_y, 0)
	position = position.lerp(actual_target_pos, delta * follow_smoothness)
	
	# B. 水平旋转
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * rotation_smoothness)
	
	# C. 缩放与动态轨道俯仰角
	if camera:
		var zoom_percent = inverse_lerp(min_dist, max_dist, target_distance)
		var target_pitch_deg = lerp(min_pitch, max_pitch, zoom_percent)
		
		var current_pitch = camera.rotation.x
		current_pitch = lerp_angle(current_pitch, deg_to_rad(target_pitch_deg), delta * zoom_smoothness)
		camera.rotation.x = current_pitch
		
		var current_dist = camera.position.length()
		var new_dist = lerp(current_dist, target_distance, delta * zoom_smoothness)
		
		var pitch_abs = abs(current_pitch)
		camera.position = Vector3(
			0.0, 
			sin(pitch_abs) * new_dist, 
			cos(pitch_abs) * new_dist
		)
