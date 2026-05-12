extends Node

# ============================================================
# 存档数据模型（替代 GameData.js）
# ============================================================

class_name GameData

const FORMAT_VERSION: int = 1

var _format_version: int = FORMAT_VERSION
var _save_time: int = 0

# 棋盘元素
var _col: int = 7
var _row: int = 5
var _elements: Dictionary = {}

# 发射器
var _lcol: int = 7
var _lrow: int = 1
var _launchers: Dictionary = {}

# 攻击槽
var _scol: int = 7
var _srow: int = 3
var _shots: Dictionary = {}

# 订单
var _order_self_id: int = 0
var _order_self: Array = []
var _order_enermy: Array = []
var _order_shop: Array = []

# 关卡/回合
var _level: int = 0
var _round: int = 0

# 道具和货币
var _items: Dictionary = {}
var _currencies: Dictionary = {}

func _init():
	_save_time = Time.get_unix_time_from_system()

func load(json_data: Dictionary) -> void:
	var defaults = {
		"_formatVersion": FORMAT_VERSION,
		"_saveTime": Time.get_unix_time_from_system(),
		"col": 7, "row": 5,
		"elements": {},
		"lcol": 7, "lrow": 1,
		"launchers": {},
		"scol": 7, "srow": 3,
		"shots": {},
		"orderSelfId": 0,
		"orderSelf": [],
		"orderEnermy": [],
		"orderShop": [],
		"level": 0,
		"round": 0,
		"items": {},
		"currencies": {},
	}
	
	# 合并默认值
	var merged = defaults.duplicate(true)
	for key in json_data:
		merged[key] = json_data[key]
	
	_format_version = merged.get("_formatVersion", FORMAT_VERSION)
	_save_time = merged.get("_saveTime", Time.get_unix_time_from_system())
	_col = merged.get("col", 7)
	_row = merged.get("row", 5)
	_elements = merged.get("elements", {}).duplicate(true) if merged.get("elements") is Dictionary else {}
	_lcol = merged.get("lcol", 7)
	_lrow = merged.get("lrow", 1)
	_launchers = merged.get("launchers", {}).duplicate(true) if merged.get("launchers") is Dictionary else {}
	_scol = merged.get("scol", 7)
	_srow = merged.get("srow", 3)
	_shots = merged.get("shots", {}).duplicate(true) if merged.get("shots") is Dictionary else {}
	_order_self_id = merged.get("orderSelfId", 0)
	_order_self = merged.get("orderSelf", []).duplicate()
	_order_enermy = merged.get("orderEnermy", []).duplicate()
	_order_shop = merged.get("orderShop", []).duplicate()
	_level = merged.get("level", 0)
	_round = merged.get("round", 0)
	_items = merged.get("items", {}).duplicate(true) if merged.get("items") is Dictionary else {}
	_currencies = merged.get("currencies", {}).duplicate(true) if merged.get("currencies") is Dictionary else {}

func to_json() -> Dictionary:
	return {
		"_formatVersion": FORMAT_VERSION,
		"_saveTime": Time.get_unix_time_from_system(),
		"col": _col,
		"row": _row,
		"elements": _elements.duplicate(true),
		"lcol": _lcol,
		"lrow": _lrow,
		"launchers": _launchers.duplicate(true),
		"scol": _scol,
		"srow": _srow,
		"shots": _shots.duplicate(true),
		"orderSelfId": _order_self_id,
		"orderSelf": _order_self.duplicate(true),
		"orderEnermy": _order_enermy.duplicate(true),
		"orderShop": _order_shop.duplicate(true),
		"level": _level,
		"round": _round,
		"items": _items.duplicate(true),
		"currencies": _currencies.duplicate(true),
	}

static func is_valid(json_data) -> bool:
	if json_data == null or typeof(json_data) != TYPE_DICTIONARY:
		return false
	var version = json_data.get("_formatVersion", 0)
	if version <= 0 or version > FORMAT_VERSION:
		return false
	return true

# ---- Properties ----
var col: int:
	get: return _col
	set(value): _col = value

var row: int:
	get: return _row
	set(value): _row = value

var elements: Dictionary:
	get: return _elements
	set(value): _elements = value

var lcol: int:
	get: return _lcol
	set(value): _lcol = value

var lrow: int:
	get: return _lrow
	set(value): _lrow = value

var launchers: Dictionary:
	get: return _launchers
	set(value): _launchers = value

var scol: int:
	get: return _scol
	set(value): _scol = value

var srow: int:
	get: return _srow
	set(value): _srow = value

var shots: Dictionary:
	get: return _shots
	set(value): _shots = value

var order_self_id: int:
	get: return _order_self_id
	set(value): _order_self_id = value

var order_self: Array:
	get: return _order_self
	set(value): _order_self = value

var order_enermy: Array:
	get: return _order_enermy
	set(value): _order_enermy = value

var order_shop: Array:
	get: return _order_shop
	set(value): _order_shop = value

var level: int:
	get: return _level
	set(value): _level = value

var round: int:
	get: return _round
	set(value): _round = value

var items: Dictionary:
	get: return _items
	set(value): _items = value

var currencies: Dictionary:
	get: return _currencies
	set(value): _currencies = value