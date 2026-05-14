extends Control
class_name ElementUI

# 子弹元素UI（替代 ElementUI.js）
# 负责管理元素槽位的显示、拖拽、点击交互
# 使用方式：
#   var ui = preload("res://ui/components/element_ui.tscn").instantiate()
#   parent.add_child(ui)
#   ui.setup(entity, area_id)

var entity  # 关联的实体
var _area_id: int = 0  # 区域ID (Launcher/Element/Shot等)

var _on_drop_complete_handler: Callable
var _on_click_handler: Callable

func setup(p_entity, p_area_id: int = 0) -> void:
	entity = p_entity
	_area_id = p_area_id
	update_event_listener()

func get_area_id() -> int:
	return _area_id

func get_entity():
	return entity

func add_icon(texture_path: String) -> void:
	if has_node("spIcon"):
		var sp_icon = get_node("spIcon") as TextureRect
		if sp_icon:
			sp_icon.texture = load(texture_path)
			sp_icon.visible = true

func icon_visible(value: bool) -> void:
	if has_node("spIcon"):
		get_node("spIcon").visible = value

func init() -> void:
	update_ui_icon()

func off_event_listener() -> void:
	if _area_id == GameConsts.AreaId_Launcher:
		if has_node("btnItem") and get_node("btnItem").has_signal("pressed"):
			get_node("btnItem").pressed.disconnect(_on_click_element)
	elif _area_id == GameConsts.AreaId_Shot:
		if has_signal("gui_input"):
			gui_input.disconnect(_on_click_element)

func update_event_listener() -> void:
	if _area_id == GameConsts.AreaId_Launcher:
		if has_node("btnItem") and get_node("btnItem").has_signal("pressed"):
			get_node("btnItem").pressed.connect(_on_click_element)
	elif _area_id == GameConsts.AreaId_Shot:
		if has_signal("gui_input"):
			gui_input.connect(_on_click_element)

func _on_drag_start() -> void:
	var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
	if not data_comp or not data_comp.data:
		return
	var data = data_comp.data
	if data:
		icon_visible(false)
		# Godot拖拽系统
		var drag_data = {"entity": entity, "data": data}
		set_drag_preview(duplicate())
		force_drag(drag_data, self)

func _on_drag_complete(from_entity_ui, to_entity) -> void:
	var from_area_id = from_entity_ui.get_area_id()
	var from_entity = from_entity_ui.get_entity()
	
	var self_ui_comp = to_entity.get_component(ComponentNames.UI) if to_entity.has_method("get_component") else null
	if self_ui_comp:
		var self_element_ui = self_ui_comp.ui
		var self_area_id = self_element_ui.get_area_id()
		
		if ((from_area_id == GameConsts.AreaId_Element or from_area_id == GameConsts.AreaId_Bullet) and self_area_id == GameConsts.AreaId_Launcher) \
			or (from_area_id == GameConsts.AreaId_Launcher and (self_area_id == GameConsts.AreaId_Element or self_area_id == GameConsts.AreaId_Bullet)):
			from_entity_ui.update_ui_icon()
			self_element_ui.update_ui_icon()
			return
	
	if _on_drop_complete_handler.is_valid():
		var is_update_by_step = _on_drop_complete_handler.call(from_entity, to_entity)
		if is_update_by_step:
			GlobalEventBus.event_ui_update_order_self.emit()
			GlobalEventBus.event_update_by_step.emit()
	
	from_entity_ui.update_ui_icon()
	if self_ui_comp:
		self_ui_comp.ui.update_ui_icon()

func update_ui_icon() -> void:
	var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
	if not data_comp or not data_comp.data:
		return
	var data = data_comp.data
	if data:
		add_icon("res://assets/icons/" + str(data.get("id", 0)) + ".png")
		icon_visible(true)
	else:
		icon_visible(false)

func _on_click_element(event: InputEvent = null) -> void:
	if event is InputEventMouseButton and not event.pressed:
		return
	var data_comp = entity.get_component(ComponentNames.DATA) if entity.has_method("get_component") else null
	if not data_comp:
		return
	var data = data_comp.data
	if data:
		if data.get("type", 0) == 2:
			if _on_click_handler.is_valid():
				_on_click_handler.call()
	else:
		var area_id = get_area_id()
		if area_id == GameConsts.AreaId_Shot:
			if _on_click_handler.is_valid():
				_on_click_handler.call()
			GlobalEventBus.event_update_by_step.emit()

func set_drop_complete_handler(handler: Callable) -> void:
	_on_drop_complete_handler = handler

func set_click_handler(handler: Callable) -> void:
	_on_click_handler = handler

func show_destroy(is_dispose: bool = false) -> void:
	icon_visible(false)
	if is_dispose:
		off_event_listener()