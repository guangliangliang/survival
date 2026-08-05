extends Node2D

@export var base_strike_count: int = 60
@export var base_damage: float = 44.0
@export var base_range: float = 220.0
@export var strike_radius: float = 58.0
@export var base_cooldown: float = 11.0
@export var storm_duration: float = 1.6
@export var lightning_bolt_scale: float = 0.12
@export var lightning_impact_scale: float = 0.3

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
	var controller = _get_game_controller()
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

func _spawn_single_strike(center: Vector2) -> void:
	var range := _get_range()
	
	# 极坐标生成：半径在 0 到 range 之间，角度任意
	var angle := randf() * TAU
	var radius := sqrt(randf()) * range
	var strike_offset := Vector2(cos(angle), sin(angle)) * radius
	
	var strike_position := center + strike_offset
	_play_lightning_effects(strike_position)
	_apply_strike_damage(strike_position)

func _play_lightning_effects(strike_position: Vector2) -> void:
	var effects := get_tree().get_first_node_in_group("visual_effects")
	if effects == null:
		return
	if effects.has_method("play_lightning_strike"):
		effects.call("play_lightning_strike", strike_position, lightning_bolt_scale, lightning_impact_scale)

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

func _draw_targeting() -> void:
	var center := to_local(target_position)
	var range := _get_range()
	draw_circle(center, range, Color(0.2, 0.55, 1.0, 0.13))
	draw_arc(center, range, 0.0, TAU, 72, Color(0.45, 0.82, 1.0, 0.78), 3.0)
	draw_arc(center, range * 0.58, 0.0, TAU, 48, Color(0.85, 0.96, 1.0, 0.5), 2.0)
	draw_circle(center, 9.0, Color(0.9, 1.0, 1.0, 0.86))

func _draw_storm_field() -> void:
	pass

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
