extends Node

# 游戏所有的交互模式都在这里定义
enum InteractionMode 
{ 
	NORMAL,
	BUILD,
	DELETE,
	INTERACT
}

# 当前的全局状态，默认是普通模式
var current_mode: InteractionMode = InteractionMode.NORMAL
