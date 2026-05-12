extends Node

# ============================================================
# 地图数据模型（替代 MapModel.js）
# 描述运行时生成的完整关卡序列
# ============================================================

class_name MapModel

var version: int = 1
var seed: int = 0
var difficulty: int = 1
var created_at: int = 0
var layers: Array = []  # Array of Dictionary nodes
var profile: Dictionary = {}
var game_rounds: Dictionary = {}  # roundId -> round data

static func create_empty_map(p_difficulty: int, p_seed: int) -> MapModel:
	var map = MapModel.new()
	map.version = 1
	map.seed = p_seed
	map.difficulty = p_difficulty
	map.created_at = Time.get_unix_time_from_system()
	map.layers = []
	map.profile = MetaConsts.get_difficulty_profile(p_difficulty)
	return map

static func validate_map_node(node: Dictionary) -> bool:
	if node.is_empty():
		return false
	if not node.has("id") or not node.has("type"):
		return false
	if not node.has("index"):
		return false
	return true

func serialize() -> Dictionary:
	return {
		"version": version,
		"seed": seed,
		"difficulty": difficulty,
		"createdAt": created_at,
		"layers": layers.duplicate(true),
		"profile": profile.duplicate(true),
		"gameRounds": game_rounds.duplicate(true),
	}