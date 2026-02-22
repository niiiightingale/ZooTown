extends Node

# ==========================================
# 🎮 全局建造状态机 (GameState)
# ==========================================
enum Mode {
	NORMAL,         # 普通模式（探索/不建造）
	BUILD_ITEM,     # 放置物件模式（树木、建筑等）
	BUILD_TERRAIN,  # 铺设地皮模式
	DELETE_ITEM,    # 锤子模式 (专砸物件)
	DELETE_TERRAIN  # 铲子模式 (专铲地皮)
}

# 当前模式，默认为普通模式
var current_mode: Mode = Mode.NORMAL

# 当前拿在手里的“画笔”资源
# 当 Mode 是 BUILD_TERRAIN 时，这里存的是 TerrainData
# 当 Mode 是 BUILD_ITEM 时，这里存的是 ItemData
var current_brush: Resource = null

# ==========================================
# 📡 信号中心：UI 和 Manager 的通讯桥梁
# ==========================================
signal mode_changed(new_mode: Mode)
signal brush_changed(new_brush: Resource)

# ==========================================
# 🛠️ 状态切换接口 (供 UI 按钮调用)
# ==========================================

# 1. 切换到铺地皮模式
func set_build_terrain_mode(terrain_res: TerrainData) -> void:
	current_brush = terrain_res
	current_mode = Mode.BUILD_TERRAIN
	brush_changed.emit(current_brush)
	mode_changed.emit(current_mode)
	print("🔧 [GameState] 进入铺地皮模式: ", terrain_res.id)

# 2. 切换到摆物件模式
func set_build_item_mode(item_res: ItemData) -> void:
	current_brush = item_res
	current_mode = Mode.BUILD_ITEM
	brush_changed.emit(current_brush)
	mode_changed.emit(current_mode)
	print("🌳 [GameState] 进入摆物件模式: ", item_res.id)

# 3. 切换到锤子模式 (拆除物件)
func set_delete_item_mode() -> void:
	current_brush = null
	current_mode = Mode.DELETE_ITEM
	brush_changed.emit(current_brush)
	mode_changed.emit(current_mode)
	print("🔨 [GameState] 进入锤子模式 (拆除物件)")

# 4. 切换到铲子模式 (拆除地皮)
func set_delete_terrain_mode() -> void:
	current_brush = null
	current_mode = Mode.DELETE_TERRAIN
	brush_changed.emit(current_brush)
	mode_changed.emit(current_mode)
	print("⛏️ [GameState] 进入铲子模式 (铲除地皮)")

# 5. 取消所有操作，回到普通模式
func set_normal_mode() -> void:
	current_brush = null
	current_mode = Mode.NORMAL
	brush_changed.emit(current_brush)
	mode_changed.emit(current_mode)
	print("🚶 [GameState] 回到普通模式")
