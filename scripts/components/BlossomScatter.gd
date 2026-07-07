extends Node2D

@export var orb_scene: PackedScene
@export var orb_pool_size: int = 96
@export var spawn_radius: float = 30.0
@export var base_orb_count: int = 8
@export var base_damage: float = 14.0
@export var base_speed: float = 480.0
@export var base_range: float = 360.0
@export var base_cooldown: float = 9.0

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0
var cast_flash_time: float = 0.0
var orb_pool: Array[Area2D] = []

func _ready() -> void:
	_build_pool()
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())
	if InputAdapter.consume_scatter_requested():
		_try_cast()
	if cast_flash_time > 0.0:
		cast_flash_time = maxf(0.0, cast_flash_time - delta)
		queue_redraw()

func _draw() -> void:
	if cast_flash_time <= 0.0:
		return
	var alpha := cast_flash_time / 0.28
	var ring_radius := 48.0 + (1.0 - alpha) * 54.0
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, Color(0.58, 0.25, 1.0, 0.48 * alpha), 5.0)
	draw_arc(Vector2.ZERO, ring_radius * 0.72, 0.0, TAU, 64, Color(0.18, 0.85, 1.0, 0.34 * alpha), 3.0)
	for index in _get_orb_count():
		var angle := TAU * float(index) / float(_get_orb_count())
		draw_circle(Vector2.from_angle(angle) * ring_radius, 4.0, Color(0.7, 0.45, 1.0, 0.72 * alpha))

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"scatter_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())

func get_active_orb_count() -> int:
	var count := 0
	for orb in orb_pool:
		if is_instance_valid(orb) and orb.get("active"):
			count += 1
	return count

func _build_pool() -> void:
	if orb_scene == null:
		return
	var owner_node: Node = get_tree().get_first_node_in_group("game_world")
	if owner_node == null:
		owner_node = get_tree().current_scene
	for index in orb_pool_size:
		var orb := orb_scene.instantiate() as Area2D
		orb.visible = false
		orb.set("active", false)
		orb.monitoring = false
		owner_node.add_child.call_deferred(orb)
		orb_pool.append(orb)

func _try_cast() -> void:
	if cooldown_remaining > 0.0:
		return
	var fired := _fire_ring()
	if fired <= 0:
		return
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_scatter_cooldown(cooldown_remaining, _get_cooldown())
	cast_flash_time = 0.28
	AudioManager.play_sfx_by_key(&"wizard_orb", -2.0)
	var controller := get_tree().get_first_node_in_group("game_controller")
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 3.0)
	queue_redraw()

func _fire_ring() -> int:
	var count := _get_orb_count()
	var fired := 0
	var start_angle := randf() * TAU
	for index in count:
		var orb := _get_orb_from_pool()
		if orb == null:
			break
		var direction := Vector2.from_angle(start_angle + TAU * float(index) / float(count))
		var spawn_position := global_position + direction * spawn_radius
		orb.call("activate", spawn_position, direction, _get_speed(), _get_damage(), _get_pierce(), _get_range())
		fired += 1
	return fired

func _get_orb_from_pool() -> Area2D:
	for orb in orb_pool:
		if is_instance_valid(orb) and not orb.get("active"):
			return orb
	return null

func _get_orb_count() -> int:
	return base_orb_count + 2 * upgrade_level

func _get_damage() -> float:
	return base_damage * (1.0 + 0.18 * float(upgrade_level))

func _get_speed() -> float:
	return base_speed + 20.0 * float(upgrade_level)

func _get_range() -> float:
	return base_range + 35.0 * float(upgrade_level)

func _get_cooldown() -> float:
	return maxf(6.5, base_cooldown - 0.5 * float(upgrade_level))

func _get_pierce() -> int:
	return 1 if upgrade_level >= 3 else 0
