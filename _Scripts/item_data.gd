extends Resource
class_name ItemData

enum ItemType {
	DECORATION, # 装饰 (如花盆)
	DEVICE,     # 装置 (如机器、帐篷)
	TERRAIN     # 地形 (地皮)
}

@export var item_name: String = "未命名物品"
@export var prefab: PackedScene           # 真实的场景预制体

@export_group("Item Classification")
@export var item_type: ItemType = ItemType.DECORATION



@export_group("Terrain Settings")
@export var terrain_rank: int = 1      

func is_terrain() -> bool:
	return item_type == ItemType.TERRAIN
