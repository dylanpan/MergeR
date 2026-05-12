extends GutTest

# ============================================================
# Buff 系统测试
# ============================================================

func test_add_buff():
	var buff_sys = BuffSystem.get_instance()
	var entity = BaseEntity.new()
	
	buff_sys.add_buff(entity, "atk_up", 5.0, -1)
	assert_true(buff_sys.has_buff(entity, "atk_up"), "实体应拥有 atk_up Buff")

func test_remove_buff():
	var buff_sys = BuffSystem.get_instance()
	var entity = BaseEntity.new()
	
	buff_sys.add_buff(entity, "def_up", 3.0, -1)
	buff_sys.remove_buff(entity, "def_up")
	assert_false(buff_sys.has_buff(entity, "def_up"), "移除后不应再拥有 def_up Buff")

func test_clear_buffs():
	var buff_sys = BuffSystem.get_instance()
	var entity = BaseEntity.new()
	
	buff_sys.add_buff(entity, "atk_up", 5.0, -1)
	buff_sys.add_buff(entity, "def_up", 3.0, -1)
	buff_sys.clear_buffs(entity)
	assert_eq(buff_sys.get_buffs(entity).size(), 0, "清除后 Buff 列表应为空")