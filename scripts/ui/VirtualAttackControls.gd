extends Control

@export var attack_radius: float = 58.0
@export var auto_radius: float = 25.0
@export var attack_center_offset := Vector2(76.0, 76.0)
@export var auto_center_offset := Vector2(150.0, 150.0)

var attack_touch_index: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(168.0, 188.0)
	set_process(false)
	queue_redraw()

func _exit_tree() -> void:
	InputAdapter.clear_virtual_attack()

func _process(_delta: float) -> void:
	if attack_touch_index != -1:
		InputAdapter.request_virtual_attack()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position, event.index)
		elif event.index == attack_touch_index:
			_release_attack()
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(event.position, -2)
		elif attack_touch_index == -2:
			_release_attack()
			accept_event()

func _handle_press(local_position: Vector2, index: int) -> void:
	if _is_inside_auto(local_position):
		InputAdapter.set_auto_attack_enabled(not InputAdapter.is_auto_attack_enabled())
		queue_redraw()
		accept_event()
	elif _is_inside_attack(local_position) and attack_touch_index == -1:
		attack_touch_index = index
		set_process(true)
		InputAdapter.request_virtual_attack()
		queue_redraw()
		accept_event()

func _release_attack() -> void:
	attack_touch_index = -1
	set_process(false)
	InputAdapter.clear_virtual_attack()
	queue_redraw()

func _is_inside_attack(local_position: Vector2) -> bool:
	return local_position.distance_to(_attack_center()) <= attack_radius

func _is_inside_auto(local_position: Vector2) -> bool:
	return local_position.distance_to(_auto_center()) <= auto_radius

func _attack_center() -> Vector2:
	return size - attack_center_offset

func _auto_center() -> Vector2:
	return size - auto_center_offset

func _draw() -> void:
	var attack_center := _attack_center()
	var auto_center := _auto_center()
	var attack_pressed := attack_touch_index != -1
	var auto_enabled := InputAdapter.is_auto_attack_enabled()
	var font := get_theme_default_font()
	draw_circle(attack_center, attack_radius, Color(0.13, 0.11, 0.09, 0.5))
	draw_circle(attack_center, attack_radius - 5.0, Color(0.95, 0.66, 0.28, 0.26 if not attack_pressed else 0.42), false, 5.0)
	draw_circle(attack_center, attack_radius * 0.58, Color(0.95, 0.5, 0.22, 0.42 if not attack_pressed else 0.7))
	draw_string(font, attack_center + Vector2(-22.0, 7.0), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1.0, 0.9, 0.68, 0.9))

	draw_circle(auto_center, auto_radius, Color(0.08, 0.1, 0.12, 0.55))
	draw_circle(auto_center, auto_radius - 3.0, Color(0.45, 0.9, 0.52, 0.65 if auto_enabled else 0.2), false, 3.0)
	if auto_enabled:
		draw_circle(auto_center, auto_radius * 0.46, Color(0.45, 0.9, 0.52, 0.62))
	draw_string(font, auto_center + Vector2(-18.0, 5.0), "AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.9, 1.0, 0.82, 0.95 if auto_enabled else 0.55))
