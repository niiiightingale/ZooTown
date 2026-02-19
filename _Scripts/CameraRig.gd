extends Node3D
class_name CameraRig 

@export_group("Follow Target")
@export var target: Node3D 
@export var follow_smoothness = 10.0

@export_group("Zoom Control")
@export var zoom_step = 8.0
@export var min_dist = 15.0
@export var max_dist = 300.0
@export var zoom_smoothness = 4.5

# (如果你以后要加四个角度切换，可以把旋转相关的变量留着，比如 target_rotation_y)

@onready var camera = $Camera3D 

var target_distance = 20.0

func _ready():
	if camera:
		target_distance = camera.position.length()

func _unhandled_input(event):
	# 现在这里清爽无比，只保留滚轮缩放
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_distance -= zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_distance += zoom_step
			target_distance = clamp(target_distance, min_dist, max_dist)

func _physics_process(delta):
	if not target: return
	
	# A. 跟随
	position = position.lerp(target.position, delta * follow_smoothness)
	
	# (如果你保留了四个角度的平滑过渡，这行可以留着)
	# rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * rotation_smoothness)
	
	# B. 缩放
	if camera:
		var direction = camera.position.normalized()
		var current_dist = camera.position.length()
		var new_dist = lerp(current_dist, target_distance, delta * zoom_smoothness)
		camera.position = direction * new_dist
