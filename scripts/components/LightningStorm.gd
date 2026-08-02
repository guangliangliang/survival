extends Node2D

@export var base_strike_count: int = 14
@export var base_damage: float = 44.0
@export var base_range: float = 220.0
@export var strike_radius: float = 58.0
@export var base_cooldown: float = 11.0
@export var storm_duration: float = 1.6
@export var mobile_max_active_bolts: int = 8

const BOLT_LIFETIME := 0.18
const BOLT_SEGMENTS := 7

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0
var is_targeting: bool = false
var target_position: Vector2 = Vector2.ZERO
var is_virtual_targeting: bool = false

var is_storming: bool = false
var storm_timer: float = 0.0
var storm_center: Vector2 = Vector2.ZERO
var strikes_remaining: int = 0
var strike_accumulator: float = 0.0
var strike_interval: float = 0.12
var active_bolts: Array = []

var mobile_performance_mode: bool = false
var _spawner: Node = null
var _game_controller: Node = null

@onready var _player: Node2D = get_parent().get_parent() as Node2D

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	InputAdapter.set_lightning_storm_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_lightning_storm_cooldown(cooldown_remaining, _get_cooldown())

	if is_storming:
		_update_storm(delta)

	_update_bolt_visuals(delta)
	_update_virtual_targeting()

	if is_targeting and not is_virtual_targeting:
		target_position = get_global_mouse_position()
		queue_redraw()

	if InputAdapter.consume_lightning_storm_requested():
		if is_targeting:
			_confirm_cast()
		else:
			_start_targeting()

func _update_virtual_targeting() -> void:
	if InputAdapter.is_virtual_lightning_storm_aiming():
		if not is_virtual_targeting:
			is_virtual_targeting = true
			is_targeting = true
		var origin := _player.global_position if _player != null else global_position
		target_position = origin + InputAdapter.get_virtual_lightning_storm_aim_offset()
		queue_redraw()
	elif is_virtual_targeting:
		is_virtual_targeting = false
		if InputAdapter.consume_virtual_lightning_storm_cast():
			_confirm_cast()
		else:
			_cancel_targeting()

func _input(event: InputEvent) -> void:
	if is_targeting:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_confirm_cast()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_pause"):
			_cancel_targeting()

func _draw() -> void:
	if is_targeting:
		_draw_targeting()
	if is_storming:
		_draw_storm_field()
	for bolt_data in active_bolts:
		var bolt: Dictionary = bolt_data
		_draw_bolt(bolt)

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"lightning_storm_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_lightning_storm_cooldown(cooldown_remaining, _get_cooldown())

func _start_targeting() -> void:
	if cooldown_remaining > 0.0:
		return
	is_targeting = true
	target_position = get_global_mouse_position()
	queue_redraw()

func _cancel_targeting() -> void:
	is_targeting = false
	queue_redraw()

func _confirm_cast() -> void:
	if cooldown_remaining > 0.0:
		return
	is_targeting = false
	storm_center = target_position
	strikes_remaining = _get_strike_count()
	if strikes_remaining <= 0:
		return
	is_storming = true
	storm_timer = 0.0
	strike_interval = storm_duration / float(strikes_remaining)
	strike_accumulator = strike_interval
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_lightning_storm_cooldown(cooldown_remaining, _get_cooldown())
	AudioManager.play_sfx_by_key(&"lightning_storm", -2.0)
	var controller := _get_game_controller()
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 5.0)
	queue_redraw()

func _update_storm(delta: float) -> void:
	storm_timer += delta
	strike_accumulator += delta
	while strike_accumulator >= strike_interval and strikes_remaining > 0:
		strike_accumulator -= strike_interval
		_spawn_single_strike(storm_center)
		strikes_remaining -= 1
	if storm_timer >= storm_duration or strikes_remaining <= 0:
		is_storming = false
	queue_redraw()

func _spawn_single_strike(center: Vector2) -> void:
	var range := _get_range()
	var strike_offset := Vector2.from_angle(randf() * TAU) * (range * sqrt(randf()))
	var strike_position := center + strike_offset
	_add_bolt_visual(strike_position)
	_apply_strike_damage(strike_position)

func _apply_strike_damage(strike_position: Vector2) -> void:
	var spawner := _get_spawner()
	var enemies: Array = spawner.call("get_active_enemies") if spawner != null and spawner.has_method("get_active_enemies") else get_tree().get_nodes_in_group("enemy")
	var radius_sq := strike_radius * strike_radius
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var offset: Vector2 = enemy.global_position - strike_position
		if offset.length_squared() > radius_sq:
			continue
		var hit_direction := offset.normalized()
		if hit_direction.length_squared() <= 0.001:
			hit_direction = Vector2.DOWN
		enemy.call("receive_hit", _get_damage(), hit_direction)

func _add_bolt_visual(strike_position: Vector2) -> void:
	if mobile_performance_mode and active_bolts.size() >= mobile_max_active_bolts:
		active_bolts.pop_front()
	var start_position := strike_position + Vector2(randf_range(-90.0, 90.0), -560.0 - randf() * 140.0)
	var path := _make_lightning_path(start_position, strike_position, BOLT_SEGMENTS, 54.0)
	var bolt := {
		"path": path,
		"branches": _make_branches(path),
		"impact": strike_position,
		"remaining": BOLT_LIFETIME,
		"lifetime": BOLT_LIFETIME,
	}
	active_bolts.append(bolt)
	queue_redraw()

func _update_bolt_visuals(delta: float) -> void:
	if active_bolts.is_empty():
		return
	for index in range(active_bolts.size() - 1, -1, -1):
		var bolt: Dictionary = active_bolts[index]
		var remaining := float(bolt.get("remaining", 0.0)) - delta
		if remaining <= 0.0:
			active_bolts.remove_at(index)
		else:
			bolt["remaining"] = remaining
			active_bolts[index] = bolt
	queue_redraw()

func _draw_targeting() -> void:
	var center := to_local(target_position)
	var range := _get_range()
	draw_circle(center, range, Color(0.2, 0.55, 1.0, 0.13))
	draw_arc(center, range, 0.0, TAU, 72, Color(0.45, 0.82, 1.0, 0.78), 3.0)
	draw_arc(center, range * 0.58, 0.0, TAU, 48, Color(0.85, 0.96, 1.0, 0.5), 2.0)
	draw_circle(center, 9.0, Color(0.9, 1.0, 1.0, 0.86))

func _draw_storm_field() -> void:
	var center := to_local(storm_center)
	var progress := clampf(storm_timer / maxf(storm_duration, 0.01), 0.0, 1.0)
	var pulse := 0.6 + 0.25 * sin(storm_timer * 28.0)
	var range := _get_range()
	draw_circle(center, range, Color(0.08, 0.24, 0.5, 0.07 * (1.0 - progress * 0.4)))
	draw_arc(center, range * (0.96 + pulse * 0.03), 0.0, TAU, 72, Color(0.35, 0.75, 1.0, 0.42), 2.0)

func _draw_bolt(bolt: Dictionary) -> void:
	var lifetime := float(bolt.get("lifetime", BOLT_LIFETIME))
	var remaining := float(bolt.get("remaining", 0.0))
	var alpha := clampf(remaining / maxf(lifetime, 0.01), 0.0, 1.0)
	var path: PackedVector2Array = bolt.get("path", PackedVector2Array())
	_draw_lightning_polyline(path, Color(0.14, 0.44, 1.0, 0.16 * alpha), 16.0)
	_draw_lightning_polyline(path, Color(0.4, 0.82, 1.0, 0.42 * alpha), 7.0)
	_draw_lightning_polyline(path, Color(0.95, 1.0, 1.0, 0.95 * alpha), 2.4)
	var branches: Array = bolt.get("branches", [])
	for branch in branches:
		var branch_path: PackedVector2Array = branch
		_draw_lightning_polyline(branch_path, Color(0.35, 0.78, 1.0, 0.26 * alpha), 5.0)
		_draw_lightning_polyline(branch_path, Color(0.92, 1.0, 1.0, 0.7 * alpha), 1.6)
	var impact: Vector2 = bolt.get("impact", Vector2.ZERO)
	var local_impact := to_local(impact)
	var bloom := strike_radius * (1.0 + (1.0 - alpha) * 0.7)
	draw_circle(local_impact, bloom, Color(0.25, 0.68, 1.0, 0.14 * alpha))
	draw_arc(local_impact, bloom, 0.0, TAU, 44, Color(0.68, 0.92, 1.0, 0.55 * alpha), 3.0)
	draw_circle(local_impact, 11.0 + (1.0 - alpha) * 12.0, Color(0.92, 1.0, 1.0, 0.62 * alpha))

func _draw_lightning_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	for index in points.size() - 1:
		draw_line(to_local(points[index]), to_local(points[index + 1]), color, width, true)

func _make_lightning_path(start: Vector2, end: Vector2, segment_count: int, jitter: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var travel := end - start
	var side := travel.orthogonal().normalized()
	if side.length_squared() <= 0.001:
		side = Vector2.RIGHT
	for index in segment_count + 1:
		if index == 0:
			points.append(start)
			continue
		if index == segment_count:
			points.append(end)
			continue
		var t := float(index) / float(segment_count)
		var taper := sin(t * PI)
		var base := start.lerp(end, t)
		var side_offset := side * randf_range(-jitter, jitter) * taper
		var vertical_noise := Vector2(randf_range(-jitter * 0.24, jitter * 0.24), 0.0) * taper
		points.append(base + side_offset + vertical_noise)
	return points

func _make_branches(path: PackedVector2Array) -> Array:
	var branches: Array = []
	if path.size() < 4:
		return branches
	var branch_count := 1 + int(randi() % 3)
	for _index in branch_count:
		var anchor_index := 1 + int(randi() % max(1, path.size() - 2))
		var previous := path[maxi(anchor_index - 1, 0)]
		var next := path[mini(anchor_index + 1, path.size() - 1)]
		var main_dir := (next - previous).normalized()
		if main_dir.length_squared() <= 0.001:
			main_dir = Vector2.DOWN
		var side := main_dir.orthogonal() * (1.0 if randf() > 0.5 else -1.0)
		var branch_end := path[anchor_index] + side * randf_range(34.0, 82.0) + main_dir * randf_range(10.0, 36.0)
		branches.append(_make_lightning_path(path[anchor_index], branch_end, 3, 16.0))
	return branches

func _get_spawner() -> Node:
	if not is_instance_valid(_spawner):
		_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	return _spawner

func _get_game_controller() -> Node:
	if not is_instance_valid(_game_controller):
		_game_controller = get_tree().get_first_node_in_group("game_controller")
	return _game_controller

func _get_strike_count() -> int:
	return base_strike_count + 3 * upgrade_level

func _get_damage() -> float:
	return base_damage * pow(1.20, float(upgrade_level))

func _get_range() -> float:
	return base_range * pow(1.10, float(upgrade_level))

func _get_cooldown() -> float:
	return maxf(8.0, base_cooldown - 0.5 * float(upgrade_level))
