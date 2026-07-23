extends Node2D

@export var sword_scene: PackedScene
@export var sword_pool_size: int = 64
@export var base_sword_count: int = 10
@export var base_damage: float = 20.0
@export var base_range: float = 200.0
@export var base_cooldown: float = 10.0

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0
var is_targeting: bool = false
var target_position: Vector2 = Vector2.ZERO
var sword_pool: Array[Area2D] = []

func _ready() -> void:
	_build_pool()
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())
	
	if is_targeting:
		target_position = get_global_mouse_position()
		queue_redraw()
	
	if InputAdapter.consume_sword_rain_requested():
		if is_targeting:
			_confirm_cast()
		else:
			_start_targeting()

func _input(event: InputEvent) -> void:
	if is_targeting:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_confirm_cast()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_pause"):
			_cancel_targeting()

func _draw() -> void:
	if not is_targeting:
		return
	var center = to_local(target_position)
	var range = _get_range()
	draw_circle(center, range, Color(0.8, 0.6, 0.2, 0.15))
	draw_arc(center, range, 0.0, TAU, 64, Color(1.0, 0.8, 0.4, 0.7), 3.0)
	draw_arc(center, range * 0.7, 0.0, TAU, 48, Color(0.9, 0.7, 0.3, 0.5), 2.0)
	draw_circle(center, 8.0, Color(1.0, 0.9, 0.5, 0.8))

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"sword_rain_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())

func _build_pool() -> void:
	if sword_scene == null:
		return
	var owner_node: Node = get_tree().get_first_node_in_group("game_world")
	if owner_node == null:
		owner_node = get_tree().current_scene
	for index in sword_pool_size:
		var sword := sword_scene.instantiate() as Area2D
		sword.visible = false
		sword.set("active", false)
		sword.monitoring = false
		owner_node.add_child.call_deferred(sword)
		sword_pool.append(sword)

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
	is_targeting = false
	var fired := _spawn_swords(target_position)
	if fired <= 0:
		return
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())
	AudioManager.play_sfx_by_key(&"wizard_orb", -2.0)
	var controller := get_tree().get_first_node_in_group("game_controller")
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 4.0)
	queue_redraw()

func _spawn_swords(center: Vector2) -> int:
	var count: int = _get_sword_count()
	var fired: int = 0
	var range: float = _get_range()
	for index in count:
		var sword := _get_sword_from_pool()
		if sword == null:
			break
		var angle := randf() * TAU
		var spawn_offset := Vector2.from_angle(angle) * (range * 0.3 + randf() * range * 0.5)
		var spawn_pos := center + spawn_offset
		var spawn_height := Vector2(randf_range(-50, 50), -400 - randf() * 200)
		sword.call("activate", spawn_pos + spawn_height, spawn_pos - spawn_pos, _get_damage())
		fired += 1
	return fired

func _get_sword_from_pool() -> Area2D:
	for sword in sword_pool:
		if is_instance_valid(sword) and not sword.get("active"):
			return sword
	return null

func _get_sword_count() -> int:
	return base_sword_count + 3 * upgrade_level

func _get_damage() -> float:
	return base_damage * pow(1.15, float(upgrade_level))

func _get_range() -> float:
	return base_range * pow(1.1, float(upgrade_level))

func _get_cooldown() -> float:
	return maxf(8.0, base_cooldown - 0.5 * float(upgrade_level))
