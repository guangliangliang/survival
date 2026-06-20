extends Node

@export var enemy_scene: PackedScene
@export var pool_size: int = 130
@export var active_enemy_limit: int = 120
@export var base_spawn_interval: float = 1.4
@export var boss_spawn_time: float = 660.0

var player: Node2D
var world_map: Node2D
var world_container: Node2D
var spawn_timer := Timer.new()
var inactive_pool: Array[CharacterBody2D] = []
var active_enemies: Array[CharacterBody2D] = []
var is_spawning: bool = false
var boss_spawned: bool = false

var enemy_catalog: Array[Resource] = [
	preload("res://resources/enemies/wolf.tres"),
	preload("res://resources/enemies/boar.tres"),
	preload("res://resources/enemies/bandit.tres"),
	preload("res://resources/enemies/gunner.tres"),
	preload("res://resources/enemies/elite.tres")
]
var boss_data: Resource = preload("res://resources/enemies/boss.tres")

func _ready() -> void:
	add_child(spawn_timer)
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = base_spawn_interval

func _process(_delta: float) -> void:
	if is_spawning and not boss_spawned and GameManager.game_time >= boss_spawn_time:
		boss_spawned = true
		spawn_enemy(boss_data)

func configure(player_node: Node2D, map_node: Node2D, container: Node2D) -> void:
	player = player_node
	world_map = map_node
	world_container = container
	_build_pool()

func _build_pool() -> void:
	if enemy_scene == null or world_container == null or not inactive_pool.is_empty():
		return
	for index in pool_size:
		var enemy := enemy_scene.instantiate() as CharacterBody2D
		world_container.add_child(enemy)
		enemy.visible = false
		enemy.set_physics_process(false)
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		enemy.connect("released", _on_enemy_released)
		inactive_pool.append(enemy)

func start_spawning() -> void:
	is_spawning = true
	boss_spawned = false
	spawn_timer.start(base_spawn_interval)

func stop_spawning() -> void:
	is_spawning = false
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	if not is_spawning or not GameManager.run_active:
		return
	var batch_size := 1 + mini(3, int(GameManager.game_time / 210.0))
	for index in batch_size:
		if active_enemies.size() >= active_enemy_limit:
			break
		var data: Resource = _choose_enemy_data()
		if data:
			spawn_enemy(data)
	var difficulty := 1.0 + GameManager.game_time / 360.0
	spawn_timer.wait_time = maxf(0.32, base_spawn_interval / difficulty)

func _choose_enemy_data() -> Resource:
	var valid: Array[Resource] = []
	var total_weight := 0.0
	for data in enemy_catalog:
		if GameManager.game_time >= data.min_spawn_time and GameManager.game_time < data.max_spawn_time:
			valid.append(data)
			total_weight += data.spawn_weight
	if valid.is_empty():
		return null
	var roll := randf() * total_weight
	for data in valid:
		roll -= data.spawn_weight
		if roll <= 0.0:
			return data
	return valid.back()

func spawn_enemy(data: Resource) -> void:
	if inactive_pool.is_empty() or not is_instance_valid(player):
		return
	var enemy: CharacterBody2D = inactive_pool.pop_back()
	active_enemies.append(enemy)
	var spawn_position := player.global_position + Vector2.from_angle(randf() * TAU) * 700.0
	if world_map and world_map.has_method("get_spawn_position"):
		spawn_position = world_map.call("get_spawn_position", data.spawn_region, player.global_position)
	enemy.call("reset_for_spawn", data, player, spawn_position)

func _on_enemy_released(enemy: CharacterBody2D) -> void:
	active_enemies.erase(enemy)
	if not inactive_pool.has(enemy):
		inactive_pool.append(enemy)

func get_active_enemy_count() -> int:
	return active_enemies.size()
