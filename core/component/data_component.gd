extends BaseComponent

# ============================================================
# 数据组件（替代 DataComponent.js）
# 存储实体的基础数据
# ============================================================

class_name DataComponent

var data: Dictionary = {}
var entity_id: String = ""

func _init(p_data: Dictionary = {}):
	comp_name = "Data"
	data = p_data
	entity_id = str(data.get("id", ""))

func init(p_data: Dictionary) -> void:
	data = p_data
	entity_id = str(data.get("id", ""))

# 处理事件总线请求
func handle_hp_data_request(entity_id_req: String, callback: Callable) -> void:
	if entity_id_req != entity_id:
		return
	var hp_data = {
		"currentHp": data.get("hp", 0),
		"maxHp": data.get("maxHp", data.get("hp", 0)),
	}
	callback.call(hp_data)

func handle_max_hp_request(entity_id_req: String, callback: Callable) -> void:
	if entity_id_req != entity_id:
		return
	var max_hp = data.get("maxHp", data.get("hp", 0))
	callback.call(max_hp)

func handle_set_invincible(entity_id_req: String, invincible: bool) -> void:
	if entity_id_req != entity_id:
		return
	data["invincible"] = invincible

func handle_apply_stats(entity_id_req: String, stats: Dictionary) -> void:
	if entity_id_req != entity_id:
		return
	if not data.has("baseHp"):
		data["baseHp"] = data.get("hp", 0)
	data["attackMultiplier"] = stats.get("attackMultiplier", 1.0)
	data["defenseMultiplier"] = stats.get("defenseMultiplier", 1.0)
	data["moveSpeed"] = stats.get("moveSpeed", 1.0)
	data["regenRate"] = stats.get("regenRate", 0)
	var base_hp = data.get("baseHp", 100)
	data["maxHp"] = base_hp * stats.get("hpMultiplier", 1.0)
	if data.get("hp", 0) > data["maxHp"]:
		data["hp"] = data["maxHp"]

func handle_heal(entity_id_req: String, amount: float) -> void:
	if entity_id_req != entity_id:
		return
	var max_hp = data.get("maxHp", data.get("hp", 100))
	data["hp"] = min(data.get("hp", 0) + amount, max_hp)

func dispose():
	data.clear()
	super.dispose()