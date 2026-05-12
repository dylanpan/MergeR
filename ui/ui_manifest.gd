extends Resource
class_name UIManifest

# ============================================================
# UI 清单配置文件
# 用于管理 UI 名称到场景/脚本路径的映射
# 
# 在 UIManager 中自动加载此文件，可覆盖内置映射
# ============================================================

# UI 路径映射表：{ "ui_name": "res://path/to/ui.tscn" 或 "res://path/to/ui.gd" }
var mapping: Dictionary = {
	# === Screen ===
	"difficulty_select": "res://ui/screens/difficulty_select_screen.tscn",
	"pick_screen": "res://ui/screens/pick_screen.tscn",
	"roguelike_screen": "res://ui/screens/roguelike_screen.tscn",
	"map_preview": "res://ui/screens/map_preview_screen.tscn",
	
	# === 通用 UI ===
	"popup_panel": "res://ui/templates/popup_panel.tscn",
	
	# === 预留 UI（待实现 .tscn） ===
	# "main_menu": "res://ui/screens/main_menu.tscn",
	# "settings": "res://ui/screens/settings.tscn",
	# "inventory": "res://ui/screens/inventory.tscn",
	# "dialog": "res://ui/screens/dialog.tscn",
	# "shop": "res://ui/screens/shop.tscn",
	# "event": "res://ui/screens/event.tscn",
	# "rest": "res://ui/screens/rest.tscn",
}

func get_mapping() -> Dictionary:
	return mapping.duplicate()