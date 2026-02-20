extends CharacterBody3D

@export var move_speed: float = 5.0

# 🎯 改动1：直接获取你的 AnimatedSprite3D 节点
@onready var anim_sprite = $AnimatedSprite3D

var is_acting: bool = false 

func _physics_process(_delta: float) -> void:
	if is_acting:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	velocity.y = 0 
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir = Vector3.ZERO
	
	var camera = get_viewport().get_camera_3d()
	if camera and input_dir != Vector2.ZERO:
		var cam_basis = camera.global_transform.basis
		var cam_fwd = -cam_basis.z
		cam_fwd.y = 0 
		cam_fwd = cam_fwd.normalized()
		
		var cam_right = cam_basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		move_dir = (cam_right * input_dir.x + cam_fwd * -input_dir.y).normalized()
	
	if move_dir:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
	_update_animation(input_dir)

# ==========================================
# 🎬 动画与翻转逻辑中心 (针对 AnimatedSprite3D)
# ==========================================
func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		# 🎯 改动2：直接让 anim_sprite 播放
		anim_sprite.play("idle")
	else:
		anim_sprite.play("walk")
		
		# 左右翻转逻辑不变，AnimatedSprite3D 也有 flip_h 属性
		if input_dir.x < 0: 
			anim_sprite.flip_h = true  
		elif input_dir.x > 0:
			anim_sprite.flip_h = false 

# ==========================================
# 🌟 对外暴露的特殊动作接口
# ==========================================
func play_happy() -> void:
	is_acting = true
	anim_sprite.play("happy")
	
	# 🎯 改动3：等待 AnimatedSprite3D 的动画完成信号
	await anim_sprite.animation_finished
	
	is_acting = false
