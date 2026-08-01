extends Node

signal game_started
signal game_ended(result: StringName)
signal player_died
signal player_revived(revives_remaining: int)
signal level_up(level: int)
signal experience_changed(current: int, required: int)
signal boss_defeated

const PERFORMANCE_TEST_CLIENT_COUNTS: Array[int] = [200, 400, 600, 800]
const PERFORMANCE_TEST_MOBILE_COUNTS: Array[int] = [40, 70, 100, 120]
const FREE_REVIVES_PER_RUN := 1

var player = null
var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 20
var game_time: float = 0.0
var kill_count: int = 0
var run_active: bool = false
var result: StringName = &""
var free_revives_remaining: int = 0
var selected_level: Resource = preload("res://resources/levels/village_outskirts.tres")
var selected_character: Resource = preload("res://resources/characters/sentinel.tres")
var last_run_result: Resource
var performance_test_enabled: bool = false
var performance_test_level: Resource = null
var performance_test_target_count: int = 0
var performance_test_keep_weapons: bool = true
var performance_test_enemy_mix: StringName = &"all"

var level_catalog: Array[Resource] = [
	preload("res://resources/levels/village_outskirts.tres"),
	preload("res://resources/levels/dark_forest.tres"),
	preload("res://resources/levels/bandit_camp.tres")
]

var character_catalog: Array[Resource] = [
	preload("res://resources/characters/sentinel.tres"),
	preload("res://resources/characters/vanguard.tres")
]

func is_mobile_performance_profile() -> bool:
	if OS.get_cmdline_user_args().has("--mobile-performance"):
		return true
	if OS.has_feature("editor"):
		return false
	if OS.has_feature("web") or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("Mobile"):
		return true
	return _is_wechat_minigame_runtime()

func _is_wechat_minigame_runtime() -> bool:
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	var is_wechat: bool = bool(bridge.call("eval", "typeof wx !== 'undefined' || typeof GameGlobal !== 'undefined'", true))
	return bool(is_wechat)

func start_run(level_data: Resource = null) -> void:
	if level_data != null:
		selected_level = level_data
	current_level = 1
	current_exp = 0
	exp_to_next_level = _calc_exp_to_next(1)
	game_time = 0.0
	kill_count = 0
	run_active = true
	result = &""
	free_revives_remaining = FREE_REVIVES_PER_RUN
	last_run_result = null
	game_started.emit()
	experience_changed.emit(current_exp, exp_to_next_level)

func start_game() -> void:
	start_run(selected_level)

func end_game(end_result: StringName = &"defeat") -> void:
	if not run_active:
		return
	run_active = false
	result = end_result
	last_run_result = RunResult.create(selected_level, result, game_time, kill_count, current_level)
	game_ended.emit(result)

func finish_run(end_result: StringName) -> Resource:
	end_game(end_result)
	return last_run_result

func try_consume_free_revive() -> bool:
	if not run_active or free_revives_remaining <= 0:
		return false
	free_revives_remaining -= 1
	return true

func select_level(level_data: Resource, clear_test_state: bool = true) -> void:
	selected_level = level_data
	if clear_test_state:
		clear_performance_test()

func select_character(character_data: Resource) -> void:
	if character_data != null:
		selected_character = character_data

func start_performance_test(level_data: Resource, target_count: int) -> void:
	if level_data == null and not level_catalog.is_empty():
		level_data = level_catalog[0]
	performance_test_enabled = true
	performance_test_level = level_data
	performance_test_target_count = maxi(1, target_count)
	performance_test_keep_weapons = true
	performance_test_enemy_mix = &"all"
	selected_level = level_data

func clear_performance_test() -> void:
	performance_test_enabled = false
	performance_test_level = null
	performance_test_target_count = 0
	performance_test_keep_weapons = true
	performance_test_enemy_mix = &"all"

func is_performance_test_active() -> bool:
	return performance_test_enabled

func get_performance_test_count_presets() -> Array[int]:
	if is_mobile_performance_profile():
		return PERFORMANCE_TEST_MOBILE_COUNTS.duplicate()
	return PERFORMANCE_TEST_CLIENT_COUNTS.duplicate()

func get_default_performance_test_count() -> int:
	return 40 if is_mobile_performance_profile() else 200

func get_performance_test_enemy_catalog() -> Array[Resource]:
	var enemies: Array[Resource] = []
	var seen := {}
	for level_data in level_catalog:
		if level_data == null:
			continue
		for enemy_data in level_data.enemy_catalog:
			if enemy_data == null or enemy_data.boss:
				continue
			var key := String(enemy_data.enemy_id)
			if seen.has(key):
				continue
			seen[key] = true
			enemies.append(enemy_data)
	return enemies

func get_level_by_id(level_id: StringName) -> Resource:
	for level_data in level_catalog:
		if level_data.level_id == level_id:
			return level_data
	return null

func get_next_level() -> Resource:
	var index := level_catalog.find(selected_level)
	if index >= 0 and index + 1 < level_catalog.size():
		return level_catalog[index + 1]
	return null

func _calc_exp_to_next(level: int) -> int:
	if level <= 5:
		return 20 + 15 * (level - 1)
	elif level <= 10:
		return int(80.0 * pow(1.20, level - 5))
	else:
		return int(200.0 * pow(1.10, level - 10))

func add_exp(amount: int) -> void:
	if not run_active:
		return
	current_exp += amount
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		current_level += 1
		exp_to_next_level = _calc_exp_to_next(current_level)
		level_up.emit(current_level)
	experience_changed.emit(current_exp, exp_to_next_level)

func add_kill(is_boss: bool = false) -> void:
	kill_count += 1
	if is_boss:
		boss_defeated.emit()

func update_game_time(delta: float) -> void:
	if run_active:
		game_time += delta
