extends Node2D

@export var base_heal_percent: float = 0.3
@export var base_cooldown: float = 15.0

var upgrade_level: int = 0
var cooldown_remaining: float = 0.0
var cast_flash_time: float = 0.0

func _ready() -> void:
	InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())
	if InputAdapter.consume_heal_requested():
		_try_cast()
	if cast_flash_time > 0.0:
		cast_flash_time = maxf(0.0, cast_flash_time - delta)
		queue_redraw()

func _draw() -> void:
	if cast_flash_time <= 0.0:
		return
	var alpha := cast_flash_time / 0.4
	var ring_radius := 60.0 + (1.0 - alpha) * 80.0
	draw_circle(Vector2.ZERO, ring_radius, Color(0.2, 1.0, 0.4, 0.15 * alpha))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, Color(0.3, 1.0, 0.5, 0.6 * alpha), 4.0)
	draw_arc(Vector2.ZERO, ring_radius * 0.6, 0.0, TAU, 48, Color(0.4, 1.0, 0.6, 0.5 * alpha), 3.0)

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"heal_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())

func _try_cast() -> void:
	if cooldown_remaining > 0.0:
		return
	var player := get_parent()
	if player == null or not player.has_method("get_health_component"):
		return
	var health_component: Node = player.get_health_component()
	if health_component == null:
		return
	var heal_amount: float = health_component.max_health * _get_heal_percent()
	health_component.heal(heal_amount)
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())
	cast_flash_time = 0.4
	AudioManager.play_sfx_by_key(&"level_up", -1.0)
	queue_redraw()

func _get_heal_percent() -> float:
	return base_heal_percent + 0.08 * float(upgrade_level)

func _get_cooldown() -> float:
	return maxf(11.0, base_cooldown - 1.0 * float(upgrade_level))
