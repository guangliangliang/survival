extends Node2D

@export var base_beam_length: float = 360.0
@export var base_beam_width: float = 46.0
@export var base_dps: float = 90.0
@export var base_sweep_duration: float = 0.9
@export var base_cooldown: float = 9.0
@export var hit_interval: float = 0.15
@export var mobile_hit_sample_interval: float = 0.05

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0

var is_sweeping: bool = false
var sweep_angle: float = 0.0
var sweep_progress: float = 0.0
var next_hit_time: Dictionary = {}
var sweep_clock: float = 0.0
var mobile_performance_mode: bool = false
var mobile_hit_sample_timer: float = 0.0
var _visual_effects: Node = null
var _spawner: Node = null
var _game_controller: Node = null

func _get_visual_effects() -> Node:
	if not is_instance_valid(_visual_effects):
		_visual_effects = get_tree().get_first_node_in_group("visual_effects")
	return _visual_effects

func _get_spawner() -> Node:
	if not is_instance_valid(_spawner):
		_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	return _spawner

func _get_game_controller() -> Node:
	if not is_instance_valid(_game_controller):
		_game_controller = get_tree().get_first_node_in_group("game_controller")
	return _game_controller

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())
	if is_sweeping:
		_update_sweep(delta)
	if InputAdapter.consume_scatter_requested():
		_try_cast()

func _draw() -> void:
	if not is_sweeping:
		return
	var length := _get_beam_length()
	var half_width := _get_beam_width() * 0.5
	var forward := Vector2.from_angle(sweep_angle)
	var side := forward.orthogonal()

	var trail_span := 0.7
	var trail_steps := 10
	for i in range(trail_steps, 0, -1):
		var t := float(i) / float(trail_steps)
		var trail_angle := sweep_angle - trail_span * t
		var tf := Vector2.from_angle(trail_angle)
		var ts := tf.orthogonal()
		var tw := half_width * (1.0 - t * 0.55)
		var alpha := (1.0 - t) * 0.20
		var poly := PackedVector2Array([
			ts * tw,
			tf * length + ts * tw * 0.6,
			tf * length - ts * tw * 0.6,
			-ts * tw,
		])
		draw_colored_polygon(poly, Color(1.0, 0.55, 0.2, alpha))

	var outer := PackedVector2Array([
		side * half_width,
		forward * length + side * half_width * 0.55,
		forward * length - side * half_width * 0.55,
		-side * half_width,
	])
	draw_colored_polygon(outer, Color(1.0, 0.45, 0.15, 0.5))

	var core_w := half_width * 0.42
	var core := PackedVector2Array([
		side * core_w,
		forward * length + side * core_w * 0.5,
		forward * length - side * core_w * 0.5,
		-side * core_w,
	])
	draw_colored_polygon(core, Color(1.0, 0.95, 0.85, 0.9))

	var pulse := 0.7 + sin(sweep_clock * 26.0) * 0.2
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.6, 0.2, 0.3 * pulse))
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.97, 0.9, 0.9))

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"scatter_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())

func get_active_orb_count() -> int:
	return 1 if is_sweeping else 0

func _try_cast() -> void:
	if cooldown_remaining > 0.0 or is_sweeping:
		return
	is_sweeping = true
	sweep_progress = 0.0
	sweep_clock = 0.0
	sweep_angle = randf() * TAU
	mobile_hit_sample_timer = 0.0
	next_hit_time.clear()
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())
	AudioManager.play_sfx_by_key(&"laser_sweep", -2.0)
	var controller := _get_game_controller()
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 3.0)
	queue_redraw()

func _update_sweep(delta: float) -> void:
	sweep_clock += delta
	var total := _get_sweep_arc()
	var step := (total / _get_sweep_duration()) * delta
	sweep_angle += step
	sweep_progress += step
	if mobile_performance_mode:
		mobile_hit_sample_timer -= delta
		if mobile_hit_sample_timer <= 0.0:
			mobile_hit_sample_timer = mobile_hit_sample_interval
			_apply_beam_damage()
	else:
		_apply_beam_damage()
	if sweep_progress >= total:
		is_sweeping = false
		next_hit_time.clear()
	queue_redraw()

func _apply_beam_damage() -> void:
	var length := _get_beam_length()
	var angle_tolerance := atan2(_get_beam_width() * 0.5, maxf(length * 0.35, 1.0))
	var forward := Vector2.from_angle(sweep_angle)
	var now := sweep_clock
	var effects := _get_visual_effects()
	var spawner := _get_spawner()
	var enemies: Array = spawner.call("get_active_enemies") if spawner != null and spawner.has_method("get_active_enemies") else get_tree().get_nodes_in_group("enemy")
	var length_sq := length * length
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance_sq := offset.length_squared()
		if distance_sq > length_sq or distance_sq < 16.0:
			continue
		var angle_diff := absf(wrapf(offset.angle() - sweep_angle, -PI, PI))
		if angle_diff > angle_tolerance:
			continue
		var enemy_id: int = enemy.get_instance_id()
		if next_hit_time.has(enemy_id) and now < next_hit_time[enemy_id]:
			continue
		next_hit_time[enemy_id] = now + hit_interval
		enemy.call("receive_hit", _get_dps() * hit_interval, forward)
		if effects != null and effects.has_method("play_impact"):
			effects.call("play_impact", enemy.global_position)

func _get_beam_length() -> float:
	return base_beam_length + 35.0 * float(upgrade_level)

func _get_beam_width() -> float:
	return base_beam_width + 6.0 * float(upgrade_level)

func _get_dps() -> float:
	return base_dps * (1.0 + 0.18 * float(upgrade_level))

func _get_sweep_arc() -> float:
	return TAU + (PI if upgrade_level >= 3 else 0.0)

func _get_sweep_duration() -> float:
	var scale := _get_sweep_arc() / TAU
	return maxf(0.5, base_sweep_duration - 0.04 * float(upgrade_level)) * scale

func _get_cooldown() -> float:
	return maxf(6.5, base_cooldown - 0.5 * float(upgrade_level))
