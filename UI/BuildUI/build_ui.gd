extends Control

# ==========================================
# 📂 资源扫描路径配置
# ==========================================
# 请确保这两个路径和你实际存放 .tres 资源的文件夹一致！
@export_dir var items_folder_path: String = "res://Item_Tres/"
@export_dir var terrains_folder_path: String = "res://Terrain_Tres/"

# 🌟 新增：把刚才做好的 GridButton.tscn 拖到检查器的这个槽位里！
@export var grid_button_scene: PackedScene
# ==========================================
# 📐 抽屉动画位置配置
# ==========================================
@export var drawer_closed_x: float = -300.0 # 藏在屏幕外的 X 坐标
@export var drawer_open_x: float = 80.0    # 弹出来后的 X 坐标 (通常在左侧菜单右边)

# ==========================================
# 🗂️ 内部数据与状态
# ==========================================
var loaded_items: Array[ItemData] = []
var loaded_terrains: Array[TerrainData] = []

enum TabCategory { VEGETATION, DECORATION, BUILDING, TERRAIN, NONE }
var current_tab: TabCategory = TabCategory.NONE
var is_drawer_open: bool = false
var tween: Tween

# ==========================================
# 📌 节点引用 (根据你实际的节点名字修改路径！)
# ==========================================
@onready var drawer_panel: PanelContainer = $DrawerPanel
@onready var item_grid: GridContainer = $DrawerPanel/MarginContainer/ScrollContainer/ItemGrid

@onready var btn_vegetation: Button = $LeftMenu/Btn_Vegetation
@onready var btn_decoration: Button = $LeftMenu/Btn_Decoration
@onready var btn_building: Button = $LeftMenu/Btn_Building
@onready var btn_terrain: Button = $LeftMenu/Btn_Terrain

@onready var btn_hammer: Button = $RightTools/Btn_Hammer
@onready var btn_shovel: Button = $RightTools/Btn_Shovel
func _unhandled_input(event: InputEvent) -> void:
	# 假设你在项目设置的输入映射里，配了一个叫 "toggle_build_menu" 的快捷键 (比如 Tab)
	if event.is_action_pressed("Build_Mode_Toggle"):
		_toggle_ui_visibility()

func _toggle_ui_visibility() -> void:
	visible = !visible # 切换显示/隐藏状态
	
	if visible:
		# 打开 UI 时：可以直接显示出来，也可以加个整体渐显动画
		print("打开建造面板")
	else:
		# 🚨 关闭 UI 时的核心联动：强行打断施法！
		# 1. 把玩家强行切回普通模式（没收画笔）
		GameState.set_normal_mode()
		# 2. 如果网格抽屉还开着，强制把它关上，重置分类状态
		if is_drawer_open:
			_close_drawer()
		current_tab = TabCategory.NONE
		print("关闭建造面板，回到普通模式")
func _ready() -> void:
	# 1. 初始化：把抽屉移到屏幕外面
	drawer_panel.position.x = drawer_closed_x
	
	# 2. 自动扫描所有本地资源
	_scan_resources()
	
	# 3. 绑定左侧分类按钮点击事件
	btn_vegetation.pressed.connect(func(): _on_tab_pressed(TabCategory.VEGETATION))
	btn_decoration.pressed.connect(func(): _on_tab_pressed(TabCategory.DECORATION))
	btn_building.pressed.connect(func(): _on_tab_pressed(TabCategory.BUILDING))
	btn_terrain.pressed.connect(func(): _on_tab_pressed(TabCategory.TERRAIN))
	
	# 4. 绑定右侧工具按钮点击事件
	btn_hammer.pressed.connect(_on_hammer_pressed)
	btn_shovel.pressed.connect(_on_shovel_pressed)
# ==========================================
# 🔍 全自动资源扫描机
# ==========================================
func _scan_resources() -> void:
	_load_files_from_dir(items_folder_path)
	_load_files_from_dir(terrains_folder_path)
	print("✅ UI扫描完成: 找到 %d 个物件, %d 个地皮" % [loaded_items.size(), loaded_terrains.size()])

func _load_files_from_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# 兼容 Godot 导出后的 .remap 后缀
				var clean_name = file_name.replace(".remap", "")
				if clean_name.ends_with(".tres"):
					var res = load(path + "/" + clean_name)
					if res is ItemData:
						loaded_items.append(res)
					elif res is TerrainData:
						loaded_terrains.append(res)
			file_name = dir.get_next()

# ==========================================
# 🖱️ 抽屉与网格逻辑
# ==========================================
func _on_tab_pressed(tab: TabCategory) -> void:
	# 如果点击的是当前已打开的分类，则收起抽屉
	if current_tab == tab and is_drawer_open:
		_close_drawer()
		current_tab = TabCategory.NONE
	else:
		# 否则，切换内容并打开抽屉
		current_tab = tab
		_populate_grid(tab)
		if not is_drawer_open:
			_open_drawer()

func _populate_grid(tab: TabCategory) -> void:
	# 1. 清空旧网格
	for child in item_grid.get_children():
		child.queue_free()
		
	# 2. 筛选当前分类下的资源
	var target_list: Array = []
	if tab == TabCategory.TERRAIN:
		target_list = loaded_terrains
	else:
		for item in loaded_items:
			# 确保 ItemCategory 枚举值 (0,1,2) 对应 TabCategory (0,1,2)
			if int(item.category) == int(tab):
				target_list.append(item)
				
	# 3. 动态生成按钮 (使用预制体)
	for res in target_list:
		# 🌟 实例化你的预制体，而不是原生的 Button.new()
		var btn = grid_button_scene.instantiate()
		
		# 🌟 找到里面的 TextureRect 节点 (名字必须和你建的一模一样)
		var icon_rect = btn.get_node("IconRect") 
		
		# 把资源的图片赋值给 TextureRect
		if res.icon != null:
			icon_rect.texture = res.icon
			
		# 绑定选中逻辑
		btn.pressed.connect(func(): _on_grid_item_selected(res))
		
		# 加进网格里
		item_grid.add_child(btn)
		print("Item添加到Drawer")

# ==========================================
# 🚀 动画控制
# ==========================================
func _open_drawer() -> void:
	is_drawer_open = true
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(drawer_panel, "position:x", drawer_open_x, 0.4)

func _close_drawer() -> void:
	is_drawer_open = false
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(drawer_panel, "position:x", drawer_closed_x, 0.3)

# ==========================================
# 📡 对接全局状态机 (下达建造命令)
# ==========================================
func _on_grid_item_selected(res: Resource) -> void:
	if res is TerrainData:
		# 你上一回合写的 global_state.gd 的单例名字必须叫 GameState
		GameState.set_build_terrain_mode(res)
	elif res is ItemData:
		GameState.set_build_item_mode(res)
	
	# 你可以选择选中物品后自动关闭抽屉，或者保持打开。这里保持打开。
	print("✅ 已选中画笔: ", res.id)

func _on_hammer_pressed() -> void:
	GameState.set_delete_item_mode()
	# 点击锤子时可以顺便关掉抽屉
	if is_drawer_open: _close_drawer()

func _on_shovel_pressed() -> void:
	GameState.set_delete_terrain_mode()
	if is_drawer_open: _close_drawer()
