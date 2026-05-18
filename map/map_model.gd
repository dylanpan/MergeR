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

static func validate_map_model(map_obj) -> bool:
	if map_obj == null:
		push_error("validate_map_model: map is null")
		return false
	
	# 验证 version
	if not map_obj.has("version") or map_obj.version != 1:
		push_error("validate_map_model: invalid version")
		return false
	
	# 验证 seed >= 0
	if not map_obj.has("seed") or map_obj.seed < 0:
		push_error("validate_map_model: invalid seed")
		return false
	
	# 验证 difficulty 1~10
	if not map_obj.has("difficulty") or map_obj.difficulty < 1 or map_obj.difficulty > 10:
		push_error("validate_map_model: invalid difficulty (must be 1-10)")
		return false
	
	# 验证 layers 是数组且非空
	if not map_obj.has("layers") or typeof(map_obj.layers) != TYPE_ARRAY or map_obj.layers.is_empty():
		push_error("validate_map_model: layers must be non-empty array")
		return false
	
	# 逐节点校验
	for i in range(map_obj.layers.size()):
		var node = map_obj.layers[i]
		if not validate_map_node(node):
			push_error("validate_map_model: node at index " + str(i) + " is invalid")
			return false
	
	# 约束：首节点必为 BATTLE
	if map_obj.layers.size() > 0:
		var first_type = map_obj.layers[0].get("type", "")
		if first_type != "battle":
			push_error("validate_map_model: first node must be BATTLE, got " + first_type)
			return false
	
	# 约束：末节点必为 BOSS
	if map_obj.layers.size() > 0:
		var last_type = map_obj.layers[-1].get("type", "")
		if last_type != "boss":
			push_error("validate_map_model: last node must be BOSS, got " + last_type)
			return false
	
	return true

static func validate_map_node(node: Dictionary) -> bool:
	if node.is_empty():
		push_error("validate_map_node: node is empty")
		return false
	if not node.has("id") or not node.has("type"):
		push_error("validate_map_node: missing id or type")
		return false
	if not node.has("index"):
		push_error("validate_map_node: missing index")
		return false
	
	# 验证 id >= 0
	var node_id = node.get("id", -1)
	if node_id < 0:
		push_error("validate_map_node: id must be >= 0")
		return false
	
	# 根据 type 验证对应字段
	var node_type = node.get("type", "")
	var valid_types = ["battle", "elite", "boss", "shop", "event", "rest", "treasure"]
	if not valid_types.has(node_type):
		push_error("validate_map_node: invalid type '" + node_type + "'")
		return false
	
	match node_type:
		"battle", "elite":
			if not node.has("roundId"):
				push_error("validate_map_node: " + node_type + " node missing roundId")
				return false
		"boss":
			if not node.has("roundId"):
				push_error("validate_map_node: boss node missing roundId")
				return false
		"shop":
			if not node.has("shopId"):
				push_error("validate_map_node: shop node missing shopId")
				return false
		"event":
			if not node.has("eventId"):
				push_error("validate_map_node: event node missing eventId")
				return false
		"rest":
			if not node.has("restId"):
				push_error("validate_map_node: rest node missing restId")
				return false
	
	return true

static func deserialize_from_json(json_data: Dictionary) -> MapModel:
	var map_obj = MapModel.new()
	map_obj.version = json_data.get("version", 1)
	map_obj.seed = json_data.get("seed", 0)
	map_obj.difficulty = json_data.get("difficulty", 1)
	map_obj.created_at = json_data.get("createdAt", Time.get_unix_time_from_system())
	map_obj.layers = json_data.get("layers", []).duplicate(true)
	map_obj.profile = json_data.get("profile", {}).duplicate(true)
	map_obj.game_rounds = json_data.get("gameRounds", {}).duplicate(true)
	
	# 验证反序列化结果
	if not validate_map_model(map_obj):
		push_error("deserialize_from_json: map validation failed")
		return null
	
	return map_obj

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
