extends GutTest

# ============================================================
# 弱点系统测试
# 使用 ConfigService 替代已移除的 MetaConsts 静态方法
# ============================================================

var _config: ConfigService

func before_each():
	_config = ConfigService.new()

func test_weakness_match():
	# 火(1) 克制 土(4)
	assert_true(_config.is_weakness(1, 4), "火应克制土")
	assert_true(_config.is_weakness(2, 1), "水应克制火")
	assert_true(_config.is_weakness(3, 2), "风应克制水")
	assert_true(_config.is_weakness(4, 3), "土应克制风")

func test_resistance_match():
	# 土(4) 被 火(1) 克制
	assert_true(_config.is_resistance(4, 1), "土应被火克制")
	assert_true(_config.is_resistance(1, 2), "火应被水克制")

func test_damage_multiplier():
	var mult = _config.get_element_damage_multiplier(1, 4)
	assert_eq(mult, 1.5, "火打土应为1.5倍伤害")
	mult = _config.get_element_damage_multiplier(1, 2)
	assert_eq(mult, 0.7, "火打水应为0.7倍伤害")
	mult = _config.get_element_damage_multiplier(1, 1)
	assert_eq(mult, 0.85, "火打火应为0.85倍伤害")

func test_difficulty_profile():
	var profile = _config.get_difficulty_profile(1)
	assert_true(profile.has("stepReduction"), "应有步数衰减配置")
	profile = _config.get_difficulty_profile(10)
	assert_eq(profile.get("stepReduction", 1.0), MetaConsts.difficultyCurves.get("expert", {}).get("stepReduction"), "高难度应使用 expert 曲线")
