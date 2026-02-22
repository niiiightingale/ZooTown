extends Resource
class_name TerrainData

@export var id: String = "unnamed_terrain" 

# 🌟 重大更新：Layer 变成了整数！0 是默认基础地皮，1、2、3... 都可以无限往上叠
@export var layer: int = 0 
@export var icon: Texture2D
# 这是原本的图集。
# 如果你没开启高级材质，它就是普通的 15 格图集。
# 如果你开启了高级材质，请在这里放入【内部纯白、外部透明的 Mask.png 遮罩图】。
@export var border_texture: Texture2D             # 带有柔边笔刷细节的边框贴纸图 (Border.png)
@export var texture: Texture2D 

@export_group("高级材质 (遮罩与边框分离)")
@export var use_world_space_texture: bool = false # 是否启用魔法遮罩？
@export var fill_texture: Texture2D               # 大尺度无缝底图 (如木板、石砖)
@export var fill_scale: float = 0.1               # 底图的缩放比例

@export_group("交互音效")
@export var place_sound: AudioStream
