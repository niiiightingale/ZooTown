extends Area3D

func _physics_process(_delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
		
	# 🌟 核心修正：抛弃位置追踪，直接“克隆”摄像机的空间姿态！
	# 这会让碰撞体的 XY 平面永远和你的屏幕绝对平行，完美复刻纸片效果
	global_rotation = cam.global_rotation
	
	# ⚠️ 如果你在可见碰撞体模式下，发现形状是背对着你的（左右反了），
	# 请把下面这行代码前面的 # 号删掉：
	# rotate_y(PI)
