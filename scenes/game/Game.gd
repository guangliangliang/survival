extends Node

@onready var game_world = $GameWorld
@onready var enemy_spawner = $EnemySpawner
@onready var camera = $Camera2D
@onready var game_ui = $CanvasLayer/GameUI
@onready var health_bar = $CanvasLayer/GameUI/HealthBar
@onready var health_label = $CanvasLayer/GameUI/HealthLabel
@onready var exp_bar = $CanvasLayer/GameUI/ExpBar
@onready var exp_label = $CanvasLayer/GameUI/ExpLabel
@onready var time_label = $CanvasLayer/GameUI/TimeLabel
@onready var kill_label = $CanvasLayer/GameUI/KillLabel
@onready var game_over_screen = $CanvasLayer/GameUI/GameOverScreen
@onready var restart_button = $CanvasLayer/GameUI/GameOverScreen/VBoxContainer/RestartButton
@onready var menu_button = $CanvasLayer/GameUI/GameOverScreen/VBoxContainer/MenuButton
@onready var pause_screen = $CanvasLayer/GameUI/PauseScreen
@onready var resume_button = $CanvasLayer/GameUI/PauseScreen/VBoxContainer2/ResumeButton
@onready var pause_menu_button = $CanvasLayer/GameUI/PauseScreen/VBoxContainer2/PauseMenuButton

var player = null
var is_paused = false

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_menu_button.pressed.connect(_on_pause_menu_button_pressed)
	
	_start_game()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_pause") and not game_over_screen.visible:
		_toggle_pause()
	
	if not is_paused:
		GameManager.update_game_time(delta)
		_update_ui()
		if player:
			camera.global_position = player.global_position

func _start_game() -> void:
	game_over_screen.visible = false
	pause_screen.visible = false
	is_paused = false
	
	player = preload("res://scenes/game/Player.tscn").instantiate()
	player.global_position = Vector2.ZERO
	game_world.add_child(player)
	
	enemy_spawner.player = player
	enemy_spawner.add_enemy_scene(preload("res://scenes/game/AnimalEnemy.tscn"))
	enemy_spawner.add_enemy_scene(preload("res://scenes/game/BanditEnemy.tscn"))
	enemy_spawner.start_spawning()
	
	GameManager.start_game()

func _toggle_pause() -> void:
	is_paused = not is_paused
	pause_screen.visible = is_paused
	get_tree().paused = is_paused
	enemy_spawner.is_spawning = not is_paused
	if is_paused:
		enemy_spawner.spawn_timer.stop()
	else:
		enemy_spawner.spawn_timer.start()

func _on_resume_button_pressed() -> void:
	_toggle_pause()

func _on_pause_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _update_ui() -> void:
	if player and "health_component" in player:
		health_bar.max_value = player.health_component.max_health
		health_bar.value = player.health_component.current_health
		health_label.text = "生命值: %d / %d" % [int(player.health_component.current_health), int(player.health_component.max_health)]
	
	exp_bar.max_value = GameManager.exp_to_next_level
	exp_bar.value = GameManager.current_exp
	exp_label.text = "经验: %d / %d - 等级 %d" % [int(GameManager.current_exp), int(GameManager.exp_to_next_level), int(GameManager.current_level)]
	
	var total_seconds = int(GameManager.game_time)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	time_label.text = "时间: %02d:%02d" % [int(minutes), int(seconds)]
	
	kill_label.text = "击杀: %d" % int(GameManager.kill_count)

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
