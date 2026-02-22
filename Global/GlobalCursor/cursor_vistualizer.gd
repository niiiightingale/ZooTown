extends Sprite2D
class_name CursorVisualizer

# --- 1. 拖入你的图片 ---
@export var tex_normal: Texture2D
@export var tex_build: Texture2D
@export var tex_delete: Texture2D

# --- 2. 直接根据 GameState.Mode 切换贴图 ---
func set_state(mode: GameState.Mode) -> void:
	match mode:
		GameState.Mode.NORMAL:
			texture = tex_normal
			print("🖱️ 光标切换: NORMAL")
		# 无论是建地皮还是建东西，都用这把建造刷子
		GameState.Mode.BUILD_ITEM, GameState.Mode.BUILD_TERRAIN:
			texture = tex_build
			print("🖱️ 光标切换: BUILD")
		# 无论是拆地皮还是拆东西，都用这把删除刷子
		GameState.Mode.DELETE_ITEM, GameState.Mode.DELETE_TERRAIN:
			texture = tex_delete
			print("🖱️ 光标切换: DELETE")
