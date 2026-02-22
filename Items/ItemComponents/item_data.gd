extends Resource
class_name ItemData

enum ItemCategory {
	VEGETATION, # 植被
	DECORATION, # 装饰物
	BUILDING    # 建筑
}

@export var id: String = "未命名物品"
@export var icon: Texture2D
@export_group("物体种类")
@export var category: ItemCategory = ItemCategory.VEGETATION   
@export var prefab: PackedScene           # 真实的场景预制体
@export_group("Placement Rules")
# 🌟 新增：允许放置的层级。默认 [0] 表示只能放在草地/泥土等基础地皮上
# 如果你想让长椅既能放草地上，也能放木板上，就在检查器里填入 0 和 1
@export var allowed_layers: Array[int] = [0]
