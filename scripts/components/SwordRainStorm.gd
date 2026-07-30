extends Node2D

@export var sword_scene: PackedScene
@export var sword_pool_size: int = 160
@export var base_sword_count: int = 40
@export var base_damage: float = 20.0
@export var base_range: float = 200.0
@export var base_cooldown: float = 10.0
@export var rain_duration: float = 2.0

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0
var is_targeting: bool = false
var target_position: Vector2 = Vector2.ZERO
var sword_pool: Array[Area2D] = []
var sword_pool_cursor: int = 0

var is_raining: bool = false
var rain_timer: float = 0.0
var rain_center: Vector2 = Vector2.ZERO
var swords_remaining: int = 0
var spawn_accumulator: float = 0.0
var spawn_interval: float = 0.05
var is_virtual_targeting: bool = false

@onready var _player: Node2D = get_parent().get_parent() as Node2D

func _ready() -> void:
	_build_pool()
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())
	
	if is_raining:
		_update_rain(delta)
	
	_update_virtual_targeting()
	
	if is_targeting and not is_virtual_targeting:
		target_position = get_global_mouse_position()
		queue_redraw()
	
	if InputAdapter.consume_sword_rain_requested():
		if is_targeting:
			_confirm_cast()
		else:
			_start_targeting()

func _update_virtual_targeting() -> void:
	if InputAdapter.is_virtual_sword_rain_aiming():
		if not is_virtual_targeting:
			is_virtual_targeting = true
			is_targeting = true
		var origin := _player.global_position if _player != null else global_position
		target_position = origin + InputAdapter.get_virtual_sword_rain_aim_offset()
		queue_redraw()
	elif is_virtual_targeting:
		is_virtual_targeting = false
		if InputAdapter.consume_virtual_sword_rain_cast():
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
	rain_center = target_position
	swords_remaining = _get_sword_count()
	if swords_remaining <= 0:
		return
	is_raining = true
	rain_timer = 0.0
	spawn_accumulator = 0.0
	spawn_interval = rain_duration / float(swords_remaining)
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_sword_rain_cooldown(cooldown_remaining, _get_cooldown())
	AudioManager.play_sfx_by_key(&"sword_rain", -2.0)
	var controller := get_tree().get_first_node_in_group("game_controller")
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 4.0)
	queue_redraw()

func _update_rain(delta: float) -> void:
	rain_timer += delta
	spawn_accumulator += delta
	while spawn_accumulator >= spawn_interval and swords_remaining > 0:
		spawn_accumulator -= spawn_interval
		_spawn_single_sword(rain_center)
		swords_remaining -= 1
	if rain_timer >= rain_duration or swords_remaining <= 0:
		is_raining = false

func _spawn_single_sword(center: Vector2) -> void:
	var sword := _get_sword_from_pool()
	if sword == null:
		return
	var range: float = _get_range()
	var angle := randf() * TAU
	var spawn_offset := Vector2.from_angle(angle) * (range * 0.3 + randf() * range * 0.5)
	var spawn_pos := center + spawn_offset
	var spawn_height := Vector2(randf_range(-50, 50), -400 - randf() * 200)
	sword.call("activate", spawn_pos + spawn_height, spawn_pos, _get_damage())

func _get_sword_from_pool() -> Area2D:
	var count := sword_pool.size()
	if count == 0:
		return null
	for offset in count:
		var index := (sword_pool_cursor + offset) % count
		var sword := sword_pool[index]
		if is_instance_valid(sword) and not sword.get("active"):
			sword_pool_cursor = (index + 1) % count
			return sword
	return null

func _get_sword_count() -> int:
	return base_sword_count + 8 * upgrade_level

func _get_damage() -> float:
	return base_damage * pow(1.15, float(upgrade_level))

func _get_range() -> float:
	return base_range * pow(1.1, float(upgrade_level))

func _get_cooldown() -> float:
	return maxf(8.0, base_cooldown - 0.5 * float(upgrade_level))
