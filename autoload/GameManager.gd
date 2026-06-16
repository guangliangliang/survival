extends Node

signal game_started
signal game_ended
signal player_died
signal level_up(level)

var player = null
var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 10
var game_time: float = 0.0
var is_paused: bool = false
var kill_count: int = 0

func _ready():
	pass

func start_game():
	current_level = 1
	current_exp = 0
	exp_to_next_level = 10
	game_time = 0.0
	is_paused = false
	kill_count = 0
	game_started.emit()

func end_game():
	is_paused = true
	game_ended.emit()

func add_exp(amount: int):
	current_exp += amount
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		current_level += 1
		exp_to_next_level = int(exp_to_next_level * 1.5)
		level_up.emit(current_level)

func add_kill():
	kill_count += 1

func update_game_time(delta: float):
	if not is_paused:
		game_time += delta
