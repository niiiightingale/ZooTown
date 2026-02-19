extends Sprite2D
class_name CursorVisualizer

# --- 1. 定义鼠标状态 ---
enum CursorState {
	NORMAL,   # 普通
	BUILD,    # 建造
	DELETE    # 删除
}

# --- 2. 拖入你的图片 ---
@export var tex_normal: Texture2D
@export var tex_build: Texture2D
@export var tex_delete: Texture2D

# --- 3. 状态切换逻辑 (保持不变) ---
func set_state(state: CursorState) -> void:
	match state:
		CursorState.NORMAL:
			texture = tex_normal
			print("Normal")
		CursorState.BUILD:
			texture = tex_build
			print("BUILD")
		CursorState.DELETE:
			texture = tex_delete
