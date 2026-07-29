extends Node2D

@export var pool_size: int = 48
@export var mobile_damage_label_interval: float = 0.05

var labels: Array[Label] = []
var mobile_performance_mode: bool = false
var next_damage_label_time: float = 0.0

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	add_to_group("combat_feedback")
	for index in pool_size:
		var label := Label.new()
		label.visible = false
		label.z_index = 20
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("ffe27a"))
		add_child(label)
		labels.append(label)

func _process(delta: float) -> void:
	for label in labels:
		if not label.visible:
			continue
		var remaining: float = float(label.get_meta("remaining", 0.0)) - delta
		label.set_meta("remaining", remaining)
		label.position.y -= 45.0 * delta
		label.modulate.a = clampf(remaining / 0.55, 0.0, 1.0)
		if remaining <= 0.0:
			label.visible = false

func show_damage(world_position: Vector2, amount: float, important: bool = false) -> void:
	if mobile_performance_mode and not important and not _can_show_mobile_damage_label():
		return
	for label in labels:
		if label.visible:
			continue
		label.text = str(int(round(amount)))
		label.global_position = world_position + Vector2(-10, -30)
		label.modulate = Color.WHITE
		label.set_meta("remaining", 0.55)
		label.visible = true
		return

func _can_show_mobile_damage_label() -> bool:
	var now := float(Time.get_ticks_msec()) * 0.001
	if now < next_damage_label_time:
		return false
	next_damage_label_time = now + mobile_damage_label_interval
	return true
