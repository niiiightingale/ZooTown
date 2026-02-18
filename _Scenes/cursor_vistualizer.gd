extends Sprite2D # 或者 Sprite2D / TextureRect，取决于你用的节点类型
class_name CursorVisualizer

# 定义鼠标状态枚举
enum CursorState {
	NORMAL,   # 普通
	BUILD,    # 建造
	DELETE    # 删除
}

# 拖入你的图片
@export var tex_normal: Texture2D
@export var tex_build: Texture2D
@export var tex_delete: Texture2D

func _ready() -> void:
	set_state(CursorState.NORMAL)
# 如果节点是 Sprite2D
func set_state(state: CursorState) -> void:
	match state:
		CursorState.NORMAL:
			texture = tex_normal # 如果是 TextureRect，这里写 texture = ...
		CursorState.BUILD:
			texture = tex_build
		CursorState.DELETE:
			texture = tex_delete
