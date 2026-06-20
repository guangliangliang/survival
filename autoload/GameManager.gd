extends Node

signal game_started
signal game_ended(result: StringName)
signal player_died
signal level_up(level: int)
signal experience_changed(current: int, required: int)
signal boss_defeated

var player = null
var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 10
var game_time: float = 0.0
var kill_count: int = 0
var run_active: bool = false
var result: StringName = &""
var selected_level: Resource = preload("res://resources/levels/village_outskirts.tres")
var last_run_result: Resource

var level_catalog: Array[Resource] = [
	preload("res://resources/levels/village_outskirts.tres"),
	preload("res://resources/levels/dark_forest.tres"),
	preload("res://resources/levels/bandit_camp.tres")
]

func start_run(level_data: Resource = null) -> void:
	if level_data != null:
		selected_level = level_data
	current_level = 1
	current_exp = 0
	exp_to_next_level = 10
	game_time = 0.0
	kill_count = 0
	run_active = true
	result = &""
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

func select_level(level_data: Resource) -> void:
	selected_level = level_data

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

func add_exp(amount: int) -> void:
	if not run_active:
		return
	current_exp += amount
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		current_level += 1
		exp_to_next_level = int(10.0 * pow(1.28, current_level - 1))
		level_up.emit(current_level)
	experience_changed.emit(current_exp, exp_to_next_level)

func add_kill(is_boss: bool = false) -> void:
	kill_count += 1
	if is_boss:
		boss_defeated.emit()

func update_game_time(delta: float) -> void:
	if run_active:
		game_time += delta
