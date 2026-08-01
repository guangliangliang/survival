extends Node

signal wave_warning(wave_data: Resource, time_left: float)
signal wave_started(wave_data: Resource)
signal wave_ended()

const WaveEvent := preload("res://scripts/data/WaveEvent.gd")
const EnemyData := preload("res://scripts/data/EnemyData.gd")
const LevelData := preload("res://scripts/data/LevelData.gd")
const Enemy := preload("res://scripts/systems/Enemy.gd")
const DEFAULT_WAVE_SPAWN_INTERVAL := 0.08
const PERFORMANCE_TEST_CLIENT_SPAWN_BATCH := 48
const PERFORMANCE_TEST_MOBILE_SPAWN_BATCH := 12
const MOBILE_PRESSURE_NONE := 0
const MOBILE_PRESSURE_HIGH := 1
const MOBILE_PRESSURE_CRITICAL := 2
const MOBILE_PRESSURE_EMERGENCY := 3

@export var enemy_scene: PackedScene
@export var pool_size: int = 350
@export var mobile_pool_size: int = 120
@export var active_enemy_limit: int = 300
@export var base_spawn_interval: float = 1.4
@export var boss_spawn_time: float = 660.0
@export var mobile_active_enemy_limit: int = 70
@export var mobile_pressure_enemy_limit: int = 50
@export var mobile_critical_enemy_limit: int = 35
@export var mobile_emergency_enemy_limit: int = 24
@export var mobile_wave_spawn_interval: float = 0.18
@export var mobile_pressure_wave_spawn_interval: float = 0.28
@export var mobile_critical_wave_spawn_interval: float = 0.42
@export var mobile_emergency_wave_spawn_interval: float = 0.6
@export var mobile_wave_end_cleanup_ratio: float = 0.7
@export var mobile_pressure_check_interval: float = 0.5
@export var mobile_pressure_cleanup_interval: float = 0.75
@export var mobile_pressure_recover_duration: float = 3.0
@export var mobile_pressure_fps_threshold: float = 46.0
@export var mobile_critical_fps_threshold: float = 34.0
@export var mobile_emergency_fps_threshold: float = 24.0
@export var mobile_recover_fps_threshold: float = 54.0

var player: Node2D
var world_map: Node2D
var world_container: Node2D
var spawn_timer := Timer.new()
var inactive_pool: Array = []
var active_enemies: Array = []
var is_spawning: bool = false
var boss_spawned: bool = false
var level_data: LevelData

var current_wave_index: int = 0
var wave_in_progress: bool = false
var wave_warning_triggered: Dictionary = {}
var wave_spawn_timer: Timer = Timer.new()
var enemies_left_to_spawn: int = 0
var mobile_performance_mode: bool = false
var mobile_normal_active_enemy_limit: int = 0
var mobile_pressure_level: int = MOBILE_PRESSURE_NONE
var mobile_pressure_check_timer: float = 0.0
var mobile_pressure_cleanup_timer: float = 0.0
var mobile_recover_timer: float = 0.0
var performance_test_mode: bool = false
var performance_test_target_count: int = 0
var performance_enemy_cursor: int = 0

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
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	if mobile_performance_mode:
		pool_size = mini(pool_size, mobile_pool_size)
	add_child(spawn_timer)
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = base_spawn_interval
	
	add_child(wave_spawn_timer)
	wave_spawn_timer.one_shot = false
	wave_spawn_timer.wait_time = _get_wave_spawn_interval()
	wave_spawn_timer.timeout.connect(_on_wave_spawn_timer_timeout)

func _reset_wave_state() -> void:
	current_wave_index = 0
	wave_in_progress = false
	wave_warning_triggered.clear()
	enemies_left_to_spawn = 0
	wave_spawn_timer.stop()

func _process(delta: float) -> void:
	if performance_test_mode and is_spawning and GameManager.run_active:
		_update_performance_test_spawns()
		return

	if mobile_performance_mode and is_spawning and GameManager.run_active:
		_update_mobile_pressure(delta)

	if is_spawning and not boss_spawned and GameManager.game_time >= boss_spawn_time:
		boss_spawned = spawn_enemy(boss_data)
	
	if is_spawning and not wave_in_progress and level_data != null:
		_check_wave_events()

func configure(config: LevelData, player_node: Node2D, map_node: Node2D, container: Node2D) -> void:
	level_data = config
	player = player_node
	world_map = map_node
	world_container = container
	performance_test_mode = GameManager.is_performance_test_active()
	performance_test_target_count = 0
	performance_enemy_cursor = 0
	if level_data != null:
		enemy_catalog = level_data.enemy_catalog.duplicate()
		boss_data = level_data.boss_data
		boss_spawn_time = level_data.boss_spawn_time
		base_spawn_interval = level_data.spawn_interval
		active_enemy_limit = mini(level_data.active_enemy_limit, pool_size - 1)
	if performance_test_mode:
		performance_test_target_count = GameManager.performance_test_target_count
		var mixed_catalog := GameManager.get_performance_test_enemy_catalog()
		if not mixed_catalog.is_empty():
			enemy_catalog = mixed_catalog
		boss_spawn_time = 0.0
		pool_size = maxi(pool_size, performance_test_target_count + 32)
		active_enemy_limit = performance_test_target_count + 1
	elif mobile_performance_mode:
		active_enemy_limit = mini(active_enemy_limit, mobile_active_enemy_limit)
	mobile_normal_active_enemy_limit = active_enemy_limit
	_reset_mobile_pressure()
	wave_spawn_timer.wait_time = _get_wave_spawn_interval()
	_build_pool()
	_reset_wave_state()

func _build_pool() -> void:
	if enemy_scene == null or world_container == null or not inactive_pool.is_empty():
		return
	for index in pool_size:
		inactive_pool.append(_create_enemy())

func _create_enemy() -> Enemy:
	var enemy := enemy_scene.instantiate() as Enemy
	world_container.add_child(enemy)
	enemy.visible = false
	enemy.set_physics_process(false)
	enemy.collision_layer = 0
	enemy.collision_mask = 0
	enemy.connect("released", _on_enemy_released)
	return enemy

func _check_wave_events() -> void:
	if level_data == null:
		return
	
	var waves: Array[Resource] = level_data.wave_events
	if current_wave_index >= waves.size():
		return
	
	var next_wave := waves[current_wave_index] as WaveEvent
	if next_wave == null:
		current_wave_index += 1
		return
	
	var time_until_wave := next_wave.trigger_time - GameManager.game_time
	
	if time_until_wave <= 0:
		_start_wave(next_wave)
	elif time_until_wave <= next_wave.warning_time and not wave_warning_triggered.has(current_wave_index):
		wave_warning_triggered[current_wave_index] = true
		wave_warning.emit(next_wave, time_until_wave)

func _start_wave(wave_data: WaveEvent) -> void:
	wave_in_progress = true
	enemies_left_to_spawn = wave_data.enemy_count
	spawn_timer.stop()
	wave_started.emit(wave_data)
	wave_spawn_timer.start(_get_wave_spawn_interval())

func _on_wave_spawn_timer_timeout() -> void:
	if not wave_in_progress or enemies_left_to_spawn <= 0:
		_end_wave()
		return
	
	if active_enemies.size() < active_enemy_limit:
		var data := _choose_enemy_data()
		if data:
			spawn_enemy(data)
			enemies_left_to_spawn -= 1

func _end_wave() -> void:
	wave_in_progress = false
	wave_spawn_timer.stop()
	current_wave_index += 1
	if mobile_performance_mode:
		_cleanup_far_enemies()
	wave_ended.emit()
	if is_spawning:
		spawn_timer.start(base_spawn_interval)

func _cleanup_far_enemies(target_count: int = -1) -> void:
	if not is_instance_valid(player):
		return
	if target_count < 0:
		target_count = int(active_enemy_limit * mobile_wave_end_cleanup_ratio)
	target_count = maxi(0, target_count)
	if active_enemies.size() <= target_count:
		return
	var player_position := player.global_position
	var removable: Array[CharacterBody2D] = []
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var data: Resource = enemy.get("enemy_data")
		if data != null and data.boss:
			continue
		removable.append(enemy)
	removable.sort_custom(func(a: CharacterBody2D, b: CharacterBody2D) -> bool:
		return a.global_position.distance_squared_to(player_position) > b.global_position.distance_squared_to(player_position))
	var to_remove := active_enemies.size() - target_count
	for enemy in removable:
		if to_remove <= 0:
			break
		if enemy.has_method("release_to_pool"):
			enemy.call("release_to_pool")
		to_remove -= 1

func start_spawning() -> void:
	is_spawning = true
	boss_spawned = false
	_reset_wave_state()
	if performance_test_mode:
		spawn_timer.stop()
		wave_spawn_timer.stop()
		_update_performance_test_spawns()
		return
	spawn_timer.start(base_spawn_interval)

func stop_spawning() -> void:
	is_spawning = false
	spawn_timer.stop()
	wave_spawn_timer.stop()

func _update_performance_test_spawns() -> void:
	if performance_test_target_count <= 0 or enemy_catalog.is_empty():
		return
	_ensure_performance_test_boss()
	var missing := performance_test_target_count - get_active_regular_enemy_count()
	if missing <= 0:
		return
	var batch_size := mini(missing, _get_performance_test_spawn_batch_size())
	for index in batch_size:
		var data := _choose_performance_test_enemy_data()
		if data == null:
			return
		if not spawn_enemy(data):
			return

func _ensure_performance_test_boss() -> void:
	if boss_data == null or has_active_boss():
		return
	boss_spawned = spawn_enemy(boss_data) or boss_spawned

func _choose_performance_test_enemy_data() -> Resource:
	if enemy_catalog.is_empty():
		return null
	var data: Resource = enemy_catalog[performance_enemy_cursor % enemy_catalog.size()]
	performance_enemy_cursor += 1
	return data

func _get_performance_test_spawn_batch_size() -> int:
	return PERFORMANCE_TEST_MOBILE_SPAWN_BATCH if mobile_performance_mode else PERFORMANCE_TEST_CLIENT_SPAWN_BATCH

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

func _reset_mobile_pressure() -> void:
	mobile_pressure_level = MOBILE_PRESSURE_NONE
	mobile_pressure_check_timer = mobile_pressure_check_interval
	mobile_pressure_cleanup_timer = mobile_pressure_cleanup_interval
	mobile_recover_timer = 0.0
	if mobile_performance_mode and not performance_test_mode:
		active_enemy_limit = _get_mobile_active_enemy_limit()

func _update_mobile_pressure(delta: float) -> void:
	mobile_pressure_check_timer -= delta
	if mobile_pressure_check_timer <= 0.0:
		mobile_pressure_check_timer = mobile_pressure_check_interval
		_sample_mobile_pressure()
	if mobile_pressure_level == MOBILE_PRESSURE_NONE:
		return
	if active_enemies.size() <= active_enemy_limit:
		return
	mobile_pressure_cleanup_timer -= delta
	if mobile_pressure_cleanup_timer <= 0.0:
		mobile_pressure_cleanup_timer = mobile_pressure_cleanup_interval
		_cleanup_far_enemies(active_enemy_limit)

func _sample_mobile_pressure() -> void:
	var fps := float(Engine.get_frames_per_second())
	if fps <= 0.0:
		return
	if fps < mobile_emergency_fps_threshold:
		mobile_recover_timer = 0.0
		_set_mobile_pressure_level(MOBILE_PRESSURE_EMERGENCY)
	elif fps < mobile_critical_fps_threshold:
		mobile_recover_timer = 0.0
		_set_mobile_pressure_level(MOBILE_PRESSURE_CRITICAL)
	elif fps < mobile_pressure_fps_threshold:
		mobile_recover_timer = 0.0
		_set_mobile_pressure_level(MOBILE_PRESSURE_HIGH)
	elif mobile_pressure_level != MOBILE_PRESSURE_NONE and fps >= mobile_recover_fps_threshold:
		mobile_recover_timer += mobile_pressure_check_interval
		if mobile_recover_timer >= mobile_pressure_recover_duration:
			_set_mobile_pressure_level(MOBILE_PRESSURE_NONE)
	else:
		mobile_recover_timer = 0.0

func _set_mobile_pressure_level(level: int) -> void:
	if mobile_pressure_level == level:
		return
	mobile_pressure_level = level
	active_enemy_limit = _get_mobile_active_enemy_limit()
	wave_spawn_timer.wait_time = _get_wave_spawn_interval()
	if not wave_spawn_timer.is_stopped():
		wave_spawn_timer.start(_get_wave_spawn_interval())
	if mobile_pressure_level != MOBILE_PRESSURE_NONE and active_enemies.size() > active_enemy_limit:
		_cleanup_far_enemies(active_enemy_limit)

func _get_mobile_active_enemy_limit() -> int:
	var limit := mobile_normal_active_enemy_limit
	match mobile_pressure_level:
		MOBILE_PRESSURE_EMERGENCY:
			limit = mini(limit, mobile_emergency_enemy_limit)
		MOBILE_PRESSURE_CRITICAL:
			limit = mini(limit, mobile_critical_enemy_limit)
		MOBILE_PRESSURE_HIGH:
			limit = mini(limit, mobile_pressure_enemy_limit)
		_:
			limit = mini(limit, mobile_active_enemy_limit)
	return maxi(1, limit)

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
	var enemy: Enemy
	if inactive_pool.is_empty():
		if not data.boss:
			return false
		enemy = _create_enemy()
	else:
		enemy = inactive_pool.pop_back() as Enemy
	active_enemies.append(enemy)
	var spawn_position := player.global_position + Vector2.from_angle(randf() * TAU) * 700.0
	if world_map and world_map.has_method("get_spawn_position"):
		spawn_position = world_map.call("get_spawn_position", data.spawn_region, player.global_position)
	enemy.reset_for_spawn(data, player, spawn_position, world_map)
	return true

func _on_enemy_released(enemy: Enemy) -> void:
	active_enemies.erase(enemy)
	if performance_test_mode and enemy != null and enemy.enemy_data != null and enemy.enemy_data.boss:
		boss_spawned = false
	if not inactive_pool.has(enemy):
		inactive_pool.append(enemy)

func get_active_enemy_count() -> int:
	return active_enemies.size()

func get_active_regular_enemy_count() -> int:
	var count := 0
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var data: Resource = enemy.get("enemy_data")
		if data != null and data.boss:
			continue
		count += 1
	return count

func has_active_boss() -> bool:
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var data: Resource = enemy.get("enemy_data")
		if data != null and data.boss:
			return true
	return false

func get_active_enemies() -> Array:
	return active_enemies

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

func clear_inactive_pool() -> void:
	for old_enemy in inactive_pool:
		if is_instance_valid(old_enemy):
			old_enemy.queue_free()
	inactive_pool.clear()

func spawn_enemy_force(data: Resource) -> Enemy:
	if data == null or not is_instance_valid(player):
		return null
	var enemy: Enemy = _create_enemy()
	active_enemies.append(enemy)
	var spawn_position := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(600.0, 1200.0)
	if world_map and world_map.has_method("get_spawn_position"):
		spawn_position = world_map.call("get_spawn_position", data.spawn_region, player.global_position)
	enemy.reset_for_spawn(data, player, spawn_position, world_map)
	return enemy

func _get_wave_spawn_interval() -> float:
	if not mobile_performance_mode:
		return DEFAULT_WAVE_SPAWN_INTERVAL
	match mobile_pressure_level:
		MOBILE_PRESSURE_EMERGENCY:
			return mobile_emergency_wave_spawn_interval
		MOBILE_PRESSURE_CRITICAL:
			return mobile_critical_wave_spawn_interval
		MOBILE_PRESSURE_HIGH:
			return mobile_pressure_wave_spawn_interval
		_:
			return mobile_wave_spawn_interval
