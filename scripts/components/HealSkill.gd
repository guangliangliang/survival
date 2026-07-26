extends Node2D

@export var base_heal_percent: float = 0.3
@export var base_cooldown: float = 15.0

const CAST_FLASH_DURATION := 0.42

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
	var alpha := cast_flash_time / CAST_FLASH_DURATION
	var bloom_radius := 54.0 + (1.0 - alpha) * 88.0
	var inner_radius := bloom_radius * 0.58
	draw_circle(Vector2.ZERO, bloom_radius, Color(0.18, 0.9, 0.36, 0.12 * alpha))
	draw_arc(Vector2.ZERO, bloom_radius, 0.0, TAU, 72, Color(0.42, 1.0, 0.58, 0.62 * alpha), 4.0)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 56, Color(0.72, 1.0, 0.66, 0.45 * alpha), 3.0)
	draw_circle(Vector2.ZERO, 18.0 + (1.0 - alpha) * 14.0, Color(0.78, 1.0, 0.62, 0.22 * alpha))

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	if stat_key == &"heal_level":
		upgrade_level += int(amount)
		cooldown_remaining = minf(cooldown_remaining, _get_cooldown())
		InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())

func _try_cast() -> void:
	if cooldown_remaining > 0.0:
		return
	var player := _get_player()
	if player == null or not player.has_method("get_health_component"):
		return
	var health_component: Node = player.get_health_component()
	if health_component == null:
		return
	var heal_amount: float = health_component.max_health * _get_heal_percent()
	health_component.heal(heal_amount)
	cooldown_remaining = _get_cooldown()
	InputAdapter.set_heal_cooldown(cooldown_remaining, _get_cooldown())
	cast_flash_time = CAST_FLASH_DURATION
	AudioManager.play_sfx_by_key(&"heal_cast", -1.0)
	_play_heal_glow()
	queue_redraw()

func _play_heal_glow() -> void:
	var effects := get_tree().get_first_node_in_group("visual_effects")
	if effects != null and effects.has_method("play_heal_glow"):
		effects.call("play_heal_glow", global_position)

func _get_heal_percent() -> float:
	return base_heal_percent + 0.08 * float(upgrade_level)

func _get_cooldown() -> float:
	return maxf(11.0, base_cooldown - 1.0 * float(upgrade_level))

func _get_player() -> Node:
	var candidate := get_parent()
	while candidate != null:
		if candidate.has_method("get_health_component"):
			return candidate
		candidate = candidate.get_parent()

	var group_player := get_tree().get_first_node_in_group("player")
	if group_player != null and group_player.has_method("get_health_component"):
		return group_player
	return null
