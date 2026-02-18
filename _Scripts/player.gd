extends CharacterBody3D

# --- 配置 ---
@export var move_speed = 15.0

# --- 引用 ---
@onready var sprite = $Sprite3D

func _physics_process(_delta):
	# 只需要处理移动，其他都交给 CameraRig 了
	update_movement()
	move_and_slide()

func update_movement():
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir = get_cam_relative_dir(input_vector)
	
	if move_dir:
		# 应用速度
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		
		# 视觉翻转逻辑
		var cam = get_viewport().get_camera_3d()
		if cam:
			# 这里为了翻转逻辑，还是得算一下右向量
			var view_vec = (self.global_position - cam.global_position)
			view_vec.y = 0
			var forward = view_vec.normalized()
			var right = forward.cross(Vector3.UP).normalized()
			
			# 调用翻转函数
			if sprite:
				var dot = move_dir.dot(right)
				if dot < -0.1: sprite.flip_h = true
				elif dot > 0.1: sprite.flip_h = false
	else:
		# 停止摩擦
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

# 工具函数：获取相对于当前激活相机的移动方向
func get_cam_relative_dir(input_vec: Vector2) -> Vector3:
	var cam = get_viewport().get_camera_3d()
	if input_vec.length() == 0 or not cam:
		return Vector3(input_vec.x, 0, input_vec.y).normalized()
	
	var view_vector = self.global_position - cam.global_position
	view_vector.y = 0
	var forward_dir = view_vector.normalized()
	var right_dir = forward_dir.cross(Vector3.UP).normalized()
	
	# W前，S后，A左，D右
	return (right_dir * input_vec.x + forward_dir * -input_vec.y).normalized()
