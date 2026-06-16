extends Node

@onready var game_world = $GameWorld
@onready var enemy_spawner = $EnemySpawner
@onready var camera = $Camera2D
@onready var game_ui = $GameUI
@onready var health_bar = $GameUI/HealthBar
@onready var health_label = $GameUI/HealthLabel
@onready var exp_bar = $GameUI/ExpBar
@onready var exp_label = $GameUI/ExpLabel
@onready var time_label = $GameUI/TimeLabel
@onready var kill_label = $GameUI/KillLabel
@onready var game_over_screen = $GameUI/GameOverScreen
@onready var restart_button = $GameUI/GameOverScreen/VBoxContainer/RestartButton
@onready var menu_button = $GameUI/GameOverScreen/VBoxContainer/MenuButton

var player = null

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	_start_game()

func _process(delta: float) -> void:
	GameManager.update_game_time(delta)
	_update_ui()
	if player:
		camera.global_position = player.global_position

func _start_game() -> void:
	game_over_screen.visible = false
	
	player = preload("res://scenes/game/Player.tscn").instantiate()
	player.global_position = Vector2.ZERO
	game_world.add_child(player)
	
	enemy_spawner.player = player
	enemy_spawner.add_enemy_scene(preload("res://scenes/game/AnimalEnemy.tscn"))
	enemy_spawner.add_enemy_scene(preload("res://scenes/game/BanditEnemy.tscn"))
	enemy_spawner.start_spawning()
	
	GameManager.start_game()

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
