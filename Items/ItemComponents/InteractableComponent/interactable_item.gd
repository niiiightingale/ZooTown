extends Node
class_name InteractableComponent

var sprite: Sprite3D
var original_scale: Vector3
var current_tween: Tween

func _ready() -> void:
	# 自动寻找父节点下的 Sprite3D
	sprite = get_parent().get_node_or_null("Sprite3D")
	if sprite:
		original_scale = sprite.scale

func on_hover_enter() -> void:
	if not sprite: return
	
	# 先干掉可能正在播放的旧动画
	if current_tween: 
		current_tween.kill()
	
	var mode = GameState.current_mode
	match mode:
		GameState.Mode.DELETE_ITEM:
			# 🧨 删除模式：稳定的爆红光 + 放大
			current_tween = create_tween() 
			sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
			current_tween.tween_property(sprite, "scale", original_scale * 1.1, 0.1)
			
		GameState.Mode.NORMAL:
			# ✨ 普通模式：微微提亮 + 弹跳
			current_tween = create_tween()
			sprite.modulate = Color(1.2, 1.2, 1.2, 1.0) 
			current_tween.tween_property(sprite, "scale", original_scale * 1.05, 0.1).set_trans(Tween.TRANS_SINE)
			
		GameState.Mode.BUILD_ITEM:
			# 🧱 建造模式：不需要动画，保持原样
			sprite.modulate = Color.WHITE

func on_hover_exit() -> void:
	if not sprite: return
	
	if current_tween: 
		current_tween.kill()
		
	# 退出悬停时播放弹回动画
	current_tween = create_tween()
	
	sprite.modulate = Color.WHITE
	current_tween.tween_property(sprite, "scale", original_scale, 0.1).set_trans(Tween.TRANS_BOUNCE)
