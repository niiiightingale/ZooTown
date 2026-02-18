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

func _ready() -> void:
	# 【新增重点 A】设置即使游戏暂停，这个节点也必须继续运行
	# 这样在菜单弹出来时，你的 _process 函数才会被执行
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	set_state(CursorState.NORMAL)

# 【新增重点 B】每帧运行的函数
func _process(_delta: float) -> void:
	# 只有当游戏处于“暂停状态”时，我们才自己控制位置。
	# 因为如果不暂停，CameraRig 会负责把我们按在屏幕中心或者原来的逻辑位置。
	if get_tree().paused:
		# 当暂停时，Input.mouse_mode 是 HIDDEN（系统鼠标在动但看不见）
		# 我们直接让图片飞到系统鼠标的位置
		global_position = get_viewport().get_mouse_position()

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
