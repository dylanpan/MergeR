extends Node

# ============================================================
# 日志工具（替代 ClearRoguelikeLogger.js）
# ============================================================

class_name Logger

enum LogLevel { DEBUG, INFO, WARN, ERROR }

static var _level: int = LogLevel.DEBUG
static var _prefix: String = "[gdRoguelike]"

static func set_level(level: int) -> void:
	_level = level

static func debug(msg: String, extra = null) -> void:
	if _level <= LogLevel.DEBUG:
		var text = _prefix + " [DEBUG] " + msg
		if extra != null:
			text += " | " + str(extra)
		print(text)

# info 方法（log 的别名，保持与 JS 兼容）
static func info(msg: String, extra = null) -> void:
	log(msg, extra)

static func log(msg: String, extra = null) -> void:
	if _level <= LogLevel.INFO:
		var text = _prefix + " [INFO] " + msg
		if extra != null:
			text += " | " + str(extra)
		print(text)

static func warn(msg: String, extra = null) -> void:
	if _level <= LogLevel.WARN:
		var text = _prefix + " [WARN] " + msg
		if extra != null:
			text += " | " + str(extra)
		push_warning(text)

static func error(msg: String, extra = null) -> void:
	if _level <= LogLevel.ERROR:
		var text = _prefix + " [ERROR] " + msg
		if extra != null:
			text += " | " + str(extra)
		push_error(text)