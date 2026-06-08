# ============================================================
# 地图导出工具 — Godot 无头模式运行
# 命令行: godot --headless --script tools/export_map.gd --difficulty 5 --seed 12345 [--output path]
#
# 策略：在 extends 之后通过 const preload 提前加载所有依赖脚本，
# 使它们的 class_name 在编译期注册，后续 autoload 编译时可正确解析。
# ============================================================

extends SceneTree

# 只加载非 autoload 的依赖脚本（避免触发项目 autoload 的运行时初始化）
const _MetaConsts = preload("res://data/meta_consts.gd")
const _GameConsts = preload("res://data/game_consts.gd")
const _GDLogger = preload("res://core/log/gd_logger.gd")
const _MapModel = preload("res://map/map_model.gd")
const _MapGenerator = preload("res://map/map_generator.gd")
const _Prng = preload("res://map/prng.gd")
const _ConfigService = preload("res://core/services/config_service.gd")

func _init():
	# var meta_consts_instance = load("res://data/meta_consts.gd").new()
	# Engine.register_singleton("MetaConsts", meta_consts_instance)

	# var game_consts_instance = load("res://data/game_consts.gd").new()
	# Engine.register_singleton("GameConsts", game_consts_instance)

	# 解析命令行参数
	var args = OS.get_cmdline_args()
	var difficulty = 5
	var seed_value = -1
	var output_path = ""
	var verbose = false

	var i = 0
	while i < args.size():
		var arg = args[i]
		if arg == "--difficulty" and i + 1 < args.size():
			difficulty = int(args[i + 1])
			i += 1
		elif arg == "--seed" and i + 1 < args.size():
			seed_value = int(args[i + 1])
			i += 1
		elif arg == "--output" and i + 1 < args.size():
			output_path = args[i + 1]
			i += 1
		elif arg == "--verbose":
			verbose = true
		i += 1

	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system())

	if verbose:
		print("[export_map] Generating map: difficulty=" + str(difficulty) + ", seed=" + str(seed_value))

	# 此时所有 class_name 已注册，可正常使用
	var map_data = MapGenerator.generate_map(difficulty, seed_value)
	var serialized = map_data.serialize()
	var json_str = JSON.stringify(serialized, "\t", false)

	if output_path.is_empty():
		print(json_str)
	else:
		var file = FileAccess.open(output_path, FileAccess.WRITE)
		if file:
			file.store_string(json_str)
			file.close()
			if verbose:
				print("[export_map] Saved to: " + output_path)
		else:
			push_error("Failed to write to: " + output_path)
			print(json_str)

	quit(0)