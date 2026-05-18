extends BaseEntity

# ============================================================
# 商店实体（替代 ShopEntity.js）
# 支持数据初始化与 ShopComponent 初始化的分离
# ============================================================

class_name ShopEntity

func get_entity_type() -> int:
	return EntityType.SHOP

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var shop_comp = ShopComponent.new(data.get("shopId", 0), data.get("shopType", 0))
	add_component(shop_comp)

func init(data: Dictionary) -> void:
	"""初始化商店数据，包括 ShopComponent"""
	var data_comp = get_component(ComponentNames.DATA) as DataComponent
	if data_comp and not data.is_empty():
		data_comp.init(data)
	
	var shop_comp = get_component(ComponentNames.SHOP) as ShopComponent
	if shop_comp and shop_comp.has_method("init"):
		shop_comp.init(data)
