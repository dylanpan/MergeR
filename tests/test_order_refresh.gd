extends GutTest

# ============================================================
# 订单刷新测试
# ============================================================

func test_create_order_enermy():
	var round_meta = {
		"id": 50001,
		"step": 20,
		"orderEnermyPool": [30001, 30002],
	}
	var enermy_datas = WorldDataManager.create_order_enermy_data(round_meta)
	assert_gt(enermy_datas.size(), 0, "应生成敌方单位数据")

func test_order_entity_hp():
	var data = {"id": 30001, "hp": 50, "def": 2, "atk": 10, "step": 5, "type": 2, "isAtker": 0, "bullets": []}
	var entity = OrderEnermyEntity.new(data)
	assert_eq(entity.get_hp(), 50, "HP应为50")
	entity.reduce_hp(20)
	assert_eq(entity.get_hp(), 30, "扣除20HP后应为30")
	entity.reduce_hp(50)
	assert_eq(entity.get_hp(), 0, "过量扣除后HP应为0")