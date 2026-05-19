extends GutTest

# ============================================================
# 地图生成器测试
# ============================================================

func test_prng_seed_reproducibility():
	var prng1 = Prng.new(12345)
	var prng2 = Prng.new(12345)
	var val1 = prng1.next_float()
	var val2 = prng2.next_float()
	assert_eq(val1, val2, "相同种子应生成相同随机序列")

func test_map_generation():
	var map_data = MapGenerator.generate_map(5, 12345)
	assert_gt(map_data.layers.size(), 0, "应生成至少1层")
	assert_eq(map_data.difficulty, 5, "难度应为5")
	assert_eq(map_data.seed, 12345, "种子应为12345")

func test_game_rounds():
	var _config = ConfigService.new()
	var profile = _config.get_difficulty_profile(5)
	var prng = Prng.new(12345)
	var rounds = MapGenerator.generate_game_rounds(profile, prng)
	assert_gt(rounds.size(), 0, "应生成至少1个回合")
