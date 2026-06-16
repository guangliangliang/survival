extends Node

@export var spawn_radius: float = 600.0
@export var base_spawn_interval: float = 2.0
@export var player: Node2D

var spawn_timer: Timer = Timer.new()
var enemy_scenes: Array[PackedScene] = []
var is_spawning: bool = false

func _ready() -> void:
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = base_spawn_interval

func add_enemy_scene(scene: PackedScene) -> void:
	enemy_scenes.append(scene)

func start_spawning() -> void:
	is_spawning = true
	spawn_timer.start()

func stop_spawning() -> void:
	is_spawning = false
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	if not is_spawning or enemy_scenes.is_empty():
		return
	spawn_enemy()
	var difficulty = 1.0 + GameManager.game_time / 60.0
	spawn_timer.wait_time = max(0.3, base_spawn_interval / difficulty)

func spawn_enemy() -> void:
	if enemy_scenes.is_empty() or not player:
		return
	var random_index = randi() % enemy_scenes.size()
	var enemy_scene = enemy_scenes[random_index]
	var enemy = enemy_scene.instantiate()
	
	var angle = randf() * TAU
	var distance = spawn_radius
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	enemy.global_position = spawn_pos
	
	get_tree().root.get_node("Game/GameWorld").add_child(enemy)
