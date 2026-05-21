extends Node

# ============================================================
# UI 管理器（Autoload 单例）
# 集中管理所有 UI 面板的创建、打开、关闭、层级控制
# ============================================================

var layers: Dictionary = {}          # { "layer_name": UILayer }
var loaded_scenes: Dictionary = {}   # { "ui_name": PackedScene }

# 预加载列表（可在项目设置或配置文件中定义）
var preloaded_resources: Array = []

# 默认层级配置
# 格式: { 层名: { 配置字段 } }
var default_layer_config = {
	"bg": {
		"z": -10,
		"block": false,
		"stack": true,
		"overlay": false,
		"color": "00000000"
	},
	"hud": {
		"z": 0,
		"block": false,
		"stack": false,
		"overlay": false,
		"color": "00000000"
	},
	"popup": {
		"z": 50,
		"block": true,
		"stack": true,
		"overlay": true,
		"color": "00000080"
	},
	"tooltip": {
		"z": 100,
		"block": false,
		"stack": false,
		"overlay": false,
		"color": "00000000"
	},
	"loading": {
		"z": 200,
		"block": true,
		"stack": false,
		"overlay": true,
		"color": "000000aa"
	}
}

# UI 名称到场景路径的映射（可扩展为从配置文件加载）
var _ui_path_mapping: Dictionary = {}


func _ready():
	# 加载 UI 路径映射
	_load_ui_mapping()
	
	# 创建默认层级
	_create_default_layers()
	
	# 预加载 UI
	for ui_name in preloaded_resources:
		preload_ui(ui_name)


func _load_ui_mapping():
	# 内置路径映射（支持 .tscn 场景和 .gd 脚本两种类型）
	_ui_path_mapping = {
		# 核心 Screen（都是 .gd 脚本）
		"difficulty_select": "res://ui/screens/difficulty_select_screen.tscn",
		"pick_screen": "res://ui/screens/pick_screen.tscn",
		"roguelike_screen": "res://ui/screens/roguelike_screen.tscn",
		"map_preview": "res://ui/screens/map_preview_screen.tscn",
		# 通用 UI
		"popup_panel": "res://ui/templates/popup_panel.tscn",
	}
	
	# 尝试加载外部配置文件覆盖（支持 .gd 和 .tres）
	for ext in [".gd", ".tres"]:
		var config_path = "res://ui/ui_manifest" + ext
		if ResourceLoader.exists(config_path):
			var manifest = load(config_path)
			if manifest is GDScript:
				manifest = manifest.new()
			if manifest is Resource and manifest.has_method("get_mapping"):
				var external_mapping = manifest.get_mapping()
				if external_mapping is Dictionary:
					for key in external_mapping:
						_ui_path_mapping[key] = external_mapping[key]
				break


func _create_default_layers():
	for name in default_layer_config:
		var cfg_dict = default_layer_config[name]
		var cfg = UILayerConfig.new()
		cfg.layer_name = name
		cfg.z_index = cfg_dict.get("z", 0)
		cfg.block_input = cfg_dict.get("block", false)
		cfg.enable_stack = cfg_dict.get("stack", true)
		cfg.show_overlay = cfg_dict.get("overlay", false)
		cfg.overlay_color = Color(cfg_dict.get("color", "00000080"))
		_create_layer(cfg)


func _create_layer(cfg: UILayerConfig):
	var layer = UILayer.new()
	layer.name = "UILayer_" + cfg.layer_name
	layer.setup(cfg)
	add_child(layer)
	layers[cfg.layer_name] = layer


# ==================== 公共 API ====================

func preload_ui(ui_name_or_path: String) -> Resource:
	# 如果已经加载过，直接返回缓存
	if loaded_scenes.has(ui_name_or_path):
		return loaded_scenes[ui_name_or_path]
	
	# 解析路径
	var path = _resolve_ui_path(ui_name_or_path)
	if path.is_empty():
		Logger.error("UIManager: 找不到 UI 路径 - " + str(ui_name_or_path))
		return null
	
	var resource = load(path)
	if resource == null:
		Logger.error("UIManager: 无法加载资源 - " + str(path))
		return null
	
	loaded_scenes[ui_name_or_path] = resource
	return resource


func _instantiate_ui(resource: Resource) -> UIBase:
	if resource is PackedScene:
		var instance = resource.instantiate()
		if instance is UIBase:
			return instance
		Logger.error("UIManager: 场景根节点不是 UIBase - " + str(resource.resource_path))
		instance.queue_free()
		return null
	elif resource is Script:
		if not resource is GDScript:
			Logger.error("UIManager: 不支持的脚本类型 - " + str(resource.resource_path))
			return null
		var instance = resource.new()
		if instance is UIBase:
			return instance
		Logger.error("UIManager: 脚本实例不是 UIBase - " + str(resource.resource_path))
		instance.queue_free()
		return null
	else:
		Logger.error("UIManager: 不支持的资源类型 - " + str(resource.resource_path))
		return null


func open_ui(ui_name: String, params = null, layer_override: String = "") -> UIBase:
	var resource = preload_ui(ui_name)
	if resource == null:
		return null
	
	var ui_instance = _instantiate_ui(resource)
	if ui_instance == null:
		return null
	
	# 确定所属层：优先使用 layer_override，否则使用 UI 自身定义的 layer_name
	var target_layer_name = layer_override if layer_override != "" else ui_instance.layer_name
	var layer = layers.get(target_layer_name)
	if not layer:
		Logger.error("UIManager: 未找到UI层 - " + str(target_layer_name))
		ui_instance.queue_free()
		return null
	
	# 添加到层
	layer.add_to_layer(ui_instance)
	
	# 调用生命周期
	ui_instance.on_opened(params)
	ui_instance.animate_in()
	
	return ui_instance


func close_ui(ui_name: String, return_data = null):
	# 遍历所有层查找该 UI
	for layer_key in layers:
		var layer = layers[layer_key]
		for ui in layer.stack:
			if ui.ui_name == ui_name:
				_do_close_ui(layer, ui, return_data)
				return return_data
	
	Logger.warn("UIManager: 未找到打开的UI - " + str(ui_name))
	return null


func close_ui_instance(ui: UIBase, return_data = null):
	if not ui or not ui.is_inside_tree():
		return
	
	# 找到 UI 所属的层
	for layer_key in layers:
		var layer = layers[layer_key]
		if layer.stack.has(ui):
			_do_close_ui(layer, ui, return_data)
			return
	
	# 如果不在任何层中，直接释放
	ui.queue_free()


func close_top(layer_name: String):
	var layer = layers.get(layer_name)
	if layer:
		var top = layer.get_top_ui()
		if top:
			close_ui(top.ui_name)


func back(layer_name: String = "popup"):
	# 回退上一层：关闭当前 UI，若有历史则自动恢复到前一个 UI
	var layer = layers.get(layer_name)
	if not layer:
		return
	
	if layer.stack.size() > 1:
		close_ui(layer.stack[-1].ui_name)
	elif layer.stack.size() == 1:
		close_ui(layer.stack[-1].ui_name)


func is_ui_open(ui_name: String) -> bool:
	for layer_key in layers:
		var layer = layers[layer_key]
		for ui in layer.stack:
			if ui.ui_name == ui_name:
				return true
	return false


func find_ui(ui_name: String) -> UIBase:
	for layer_key in layers:
		var layer = layers[layer_key]
		for ui in layer.stack:
			if ui.ui_name == ui_name:
				return ui
	return null


func close_all():
	for layer_key in layers:
		layers[layer_key].clear_layer()


# ==================== 内部方法 ====================

func _do_close_ui(layer: UILayer, ui: UIBase, return_data = null):
	# 发送 closed 信号
	ui.closed.emit(return_data)
	
	# 调用关闭生命周期
	ui.on_closed()
	
	# 播放关闭动画
	ui.animate_out()
	
	# 注意：animate_out 内部会 queue_free，所以这里用 skip_free=true
	await ui.tree_exited
	layer.remove_from_layer(ui, true)


func _resolve_ui_path(ui_name_or_path: String) -> String:
	# 如果已经是 .tscn 或 .gd 路径，直接返回
	if ui_name_or_path.ends_with(".tscn") or ui_name_or_path.ends_with(".gd"):
		return ui_name_or_path
	
	# 从映射中查找
	if _ui_path_mapping.has(ui_name_or_path):
		return _ui_path_mapping[ui_name_or_path]
	
	# 尝试自动拼接路径（先试 .tscn，再试 .gd）
	var extensions = [".tscn", ".gd"]
	var search_patterns = [
		"res://ui/" + ui_name_or_path,
		"res://ui/screens/" + ui_name_or_path + "_screen",
		"res://ui/screens/" + ui_name_or_path,
		"res://ui/components/" + ui_name_or_path,
		"res://ui/templates/" + ui_name_or_path,
	]
	
	for pattern in search_patterns:
		for ext in extensions:
			var guessed_path = pattern + ext
			if ResourceLoader.exists(guessed_path):
				return guessed_path
	
	return ""
