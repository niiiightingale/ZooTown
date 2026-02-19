@tool
extends EditorPlugin

var pie_ui: Control

func _enter_tree() -> void:
	pie_ui = preload("res://addons/blender_pie_menu/pie_menu_ui.gd").new()
	pie_ui.hide()
	
	# 强行塞进真实 3D 视窗的容器里
	var viewport_3d = EditorInterface.get_editor_viewport_3d(0)
	if viewport_3d and viewport_3d.get_parent():
		viewport_3d.get_parent().add_child(pie_ui)

func _exit_tree() -> void:
	if pie_ui:
		pie_ui.queue_free()

# 🌟 在这里监听全局按键，优先级更高
func _input(event: InputEvent) -> void:
	# 只有在 3D 编辑界面才生效
	if not pie_ui or not pie_ui.get_parent().is_visible_in_tree():
		return

	if event is InputEventKey and event.keycode == KEY_QUOTELEFT:
		if event.pressed and not event.is_echo():
			# 只要鼠标在 3D 区域内，就强制呼出
			var mouse_pos = pie_ui.get_global_mouse_position()
			if pie_ui.get_parent().get_global_rect().has_point(mouse_pos):
				pie_ui.open_menu()
				# 告诉编辑器，这个按键已经被我处理了，不要乱动
				get_viewport().set_input_as_handled() 
				
		elif not event.pressed and pie_ui.visible:
			pie_ui.close_menu()
			get_viewport().set_input_as_handled()
