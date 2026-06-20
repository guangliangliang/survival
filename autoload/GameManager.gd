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

func start_game() -> void:
	current_level = 1
	current_exp = 0
	exp_to_next_level = 10
	game_time = 0.0
	kill_count = 0
	run_active = true
	result = &""
	game_started.emit()
	experience_changed.emit(current_exp, exp_to_next_level)

func end_game(end_result: StringName = &"defeat") -> void:
	if not run_active:
		return
	run_active = false
	result = end_result
	game_ended.emit(result)

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
