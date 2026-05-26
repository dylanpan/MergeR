extends Node

# 主场景入口脚本
# 项目启动后初始化 UI 系统并打开难度选择界面

func _ready() -> void:
	# 等待一帧确保所有 Autoload 初始化完成
	await get_tree().process_frame
	
	# 打开难度选择界面
	if UIManager and UIManager.has_method("open_ui"):
		UIManager.open_ui("difficulty_select", {
			"difficulty": 5
		})
	else:
		GDLogger.error("UIManager 未就绪")
