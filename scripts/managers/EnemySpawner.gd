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
var level_data: Resource

var enemy_catalog: Array[Resource] = [
	preload("res://resources/enemies/wolf.tres"),
	preload("res://resources/enemies/boar.tres"),
	preload("res://resources/enemies/thorn_porcupine.tres"),
	preload("res://resources/enemies/bandit.tres"),
	preload("res://resources/enemies/cult_wizard.tres"),
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
		boss_spawned = spawn_enemy(boss_data)

func configure(config: Resource, player_node: Node2D, map_node: Node2D, container: Node2D) -> void:
	level_data = config
	player = player_node
	world_map = map_node
	world_container = container
	if level_data != null:
		enemy_catalog = level_data.enemy_catalog.duplicate()
		boss_data = level_data.boss_data
		boss_spawn_time = level_data.boss_spawn_time
		base_spawn_interval = level_data.spawn_interval
		active_enemy_limit = mini(level_data.active_enemy_limit, pool_size - 1)
	_build_pool()

func _build_pool() -> void:
	if enemy_scene == null or world_container == null or not inactive_pool.is_empty():
		return
	for index in pool_size:
		inactive_pool.append(_create_enemy())

func _create_enemy() -> CharacterBody2D:
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	world_container.add_child(enemy)
	enemy.visible = false
	enemy.set_physics_process(false)
	enemy.collision_layer = 0
	enemy.collision_mask = 0
	enemy.connect("released", _on_enemy_released)
	return enemy

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
	var level_multiplier: float = level_data.difficulty_multiplier if level_data != null else 1.0
	var difficulty := (1.0 + GameManager.game_time / 360.0) * level_multiplier
	spawn_timer.wait_time = maxf(0.32, base_spawn_interval / difficulty)

func _choose_enemy_data() -> Resource:
	var valid: Array[Resource] = []
	var total_weight := 0.0
	var schedule_time := GameManager.game_time
	if level_data != null and level_data.duration > 0.0:
		schedule_time *= 720.0 / level_data.duration
	for data in enemy_catalog:
		if schedule_time >= data.min_spawn_time and schedule_time < data.max_spawn_time:
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

func spawn_enemy(data: Resource) -> bool:
	if data == null or not is_instance_valid(player):
		return false
	var enemy: CharacterBody2D
	if inactive_pool.is_empty():
		if not data.boss:
			return false
		enemy = _create_enemy()
	else:
		enemy = inactive_pool.pop_back()
	active_enemies.append(enemy)
	var spawn_position := player.global_position + Vector2.from_angle(randf() * TAU) * 700.0
	if world_map and world_map.has_method("get_spawn_position"):
		spawn_position = world_map.call("get_spawn_position", data.spawn_region, player.global_position)
	enemy.call("reset_for_spawn", data, player, spawn_position)
	return true

func _on_enemy_released(enemy: CharacterBody2D) -> void:
	active_enemies.erase(enemy)
	if not inactive_pool.has(enemy):
		inactive_pool.append(enemy)

func get_active_enemy_count() -> int:
	return active_enemies.size()

func get_nearest_enemy(origin: Vector2, max_range: float) -> Node2D:
	var nearest: Node2D
	var min_distance_sq := max_range * max_range
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var distance_sq := origin.distance_squared_to(enemy.global_position)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			nearest = enemy
	return nearest
