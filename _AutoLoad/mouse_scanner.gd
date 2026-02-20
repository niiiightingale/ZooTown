extends Node

var hovered_object: Node3D = null      
var ground_position: Vector3 = Vector3.ZERO 
var is_mouse_on_ground: bool = false   

func _physics_process(_delta: float) -> void:
	var viewport = get_viewport()
	var cam = viewport.get_camera_3d()
	if not cam: return
	
	var mouse_pos = viewport.get_mouse_position()
	var from = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	var to = from + ray_dir * 1000.0
	var space_state = cam.get_world_3d().direct_space_state
	
	# === 1. 扫描可交互实体 (只扫 Layer 2 的 ClickArea) ===
	var query_obj = PhysicsRayQueryParameters3D.create(from, to)
	query_obj.collision_mask = 2 
	query_obj.collide_with_areas = true
	var result_obj = space_state.intersect_ray(query_obj)
	
	var new_hovered_obj = null
	if result_obj:
		var curr = result_obj.collider
		while curr and curr != get_tree().root:
			# 只要身上带这些组件，就说明是可以交互的合法物体
			if curr.has_node("DestructibleComponent") or curr.has_node("InteractableComponent"):
				new_hovered_obj = curr
				break
			curr = curr.get_parent()
			
	# 💡 核心：当鼠标指的物体发生变化时，通知它们！
	# 💡 核心：当鼠标指的物体发生变化时，通知它们身上的组件！
	if new_hovered_obj != hovered_object:
		# 1. 让旧物体关灯
		if hovered_object and is_instance_valid(hovered_object):
			var old_comp = hovered_object.get_node_or_null("InteractableComponent")
			if old_comp and old_comp.has_method("on_hover_exit"):
				old_comp.on_hover_exit() 
				
		hovered_object = new_hovered_obj
		
		# 2. 让新物体开灯
		if hovered_object and is_instance_valid(hovered_object):
			var new_comp = hovered_object.get_node_or_null("InteractableComponent")
			if new_comp and new_comp.has_method("on_hover_enter"):
				new_comp.on_hover_enter()
				
	# === 2. 扫描地面建造点 (不变) ===
	var ground_plane = Plane(Vector3.UP, 0.0)
	var intersection = ground_plane.intersects_ray(from, ray_dir)
	if intersection != null:
		ground_position = intersection
		is_mouse_on_ground = true
	else:
		is_mouse_on_ground = false

# 💡 补充一个实用功能：当玩家没有移动鼠标，但用快捷键切换了模式时，强制刷新一下动画
func refresh_current_hover() -> void:
	if hovered_object and is_instance_valid(hovered_object):
		if hovered_object.has_method("on_hover_enter"):
			hovered_object.on_hover_enter()
