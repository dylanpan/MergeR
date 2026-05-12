extends BaseEntity

# ============================================================
# 商店实体（替代 ShopEntity.js）
# ============================================================

class_name ShopEntity

func _init(data: Dictionary = {}):
	var data_comp = DataComponent.new(data)
	add_component(data_comp)
	
	var shop_comp = ShopComponent.new(data.get("shopId", 0), data.get("shopType", 0))
	add_component(shop_comp)