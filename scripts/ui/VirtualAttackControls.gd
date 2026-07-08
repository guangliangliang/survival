extends Control

const ICON_ATTACK := preload("res://assets/images/ui/icons/attack.svg")
const ICON_AUTO := preload("res://assets/images/ui/icons/auto.svg")
const ICON_DASH := preload("res://assets/images/ui/icons/dash.svg")
const ICON_SKILL := preload("res://assets/images/ui/icons/skill.svg")

@export var attack_radius: float = 58.0
@export var auto_radius: float = 25.0
@export var dash_radius: float = 42.0
@export var scatter_radius: float = 34.0
@export var attack_center_offset := Vector2(76.0, 76.0)
@export var auto_center_offset := Vector2(206.0, 150.0)
@export var dash_center_offset := Vector2(166.0, 76.0)
@export var scatter_center_offset := Vector2(76.0, 166.0)

var attack_touch_index: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(250.0, 188.0)
	set_process(true)
	queue_redraw()

func _exit_tree() -> void:
	InputAdapter.clear_virtual_attack()
	InputAdapter.clear_virtual_dash()
	InputAdapter.clear_virtual_scatter()

func _process(_delta: float) -> void:
	if attack_touch_index != -1:
		InputAdapter.request_virtual_attack()
	queue_redraw()

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
	elif _is_inside_scatter(local_position):
		InputAdapter.request_virtual_scatter()
		queue_redraw()
		accept_event()
	elif _is_inside_dash(local_position):
		InputAdapter.request_virtual_dash()
		queue_redraw()
		accept_event()
	elif _is_inside_attack(local_position) and attack_touch_index == -1:
		attack_touch_index = index
		InputAdapter.request_virtual_attack()
		queue_redraw()
		accept_event()

func _release_attack() -> void:
	attack_touch_index = -1
	InputAdapter.clear_virtual_attack()
	queue_redraw()

func _is_inside_attack(local_position: Vector2) -> bool:
	return local_position.distance_to(_attack_center()) <= attack_radius

func _is_inside_auto(local_position: Vector2) -> bool:
	return local_position.distance_to(_auto_center()) <= auto_radius

func _is_inside_dash(local_position: Vector2) -> bool:
	return local_position.distance_to(_dash_center()) <= dash_radius

func _is_inside_scatter(local_position: Vector2) -> bool:
	return local_position.distance_to(_scatter_center()) <= scatter_radius

func _attack_center() -> Vector2:
	return size - attack_center_offset

func _auto_center() -> Vector2:
	return size - auto_center_offset

func _dash_center() -> Vector2:
	return size - dash_center_offset

func _scatter_center() -> Vector2:
	return size - scatter_center_offset

func _draw() -> void:
	var attack_center := _attack_center()
	var auto_center := _auto_center()
	var dash_center := _dash_center()
	var scatter_center := _scatter_center()
	var attack_pressed := attack_touch_index != -1
	var auto_enabled := InputAdapter.is_auto_attack_enabled()
	var dash_ready := InputAdapter.is_dash_ready()
	var scatter_ready := InputAdapter.is_scatter_ready()
	draw_circle(attack_center, attack_radius, Color(0.13, 0.11, 0.09, 0.5))
	draw_circle(attack_center, attack_radius - 5.0, Color(0.95, 0.66, 0.28, 0.26 if not attack_pressed else 0.42), false, 5.0)
	draw_circle(attack_center, attack_radius * 0.58, Color(0.95, 0.5, 0.22, 0.42 if not attack_pressed else 0.7))
	_draw_icon(ICON_ATTACK, attack_center, 48.0, 0.92 if not attack_pressed else 1.0)

	draw_circle(dash_center, dash_radius, Color(0.08, 0.09, 0.1, 0.52))
	draw_circle(dash_center, dash_radius - 4.0, Color(0.62, 0.74, 0.95, 0.52 if dash_ready else 0.16), false, 4.0)
	draw_circle(dash_center, dash_radius * 0.56, Color(0.3, 0.55, 0.9, 0.58 if dash_ready else 0.18))
	_draw_icon(ICON_DASH, dash_center, 36.0, 0.95 if dash_ready else 0.35)

	draw_circle(auto_center, auto_radius, Color(0.08, 0.1, 0.12, 0.55))
	draw_circle(auto_center, auto_radius - 3.0, Color(0.45, 0.9, 0.52, 0.65 if auto_enabled else 0.2), false, 3.0)
	if auto_enabled:
		draw_circle(auto_center, auto_radius * 0.46, Color(0.45, 0.9, 0.52, 0.62))
	_draw_icon(ICON_AUTO, auto_center, 25.0, 0.95 if auto_enabled else 0.5)

	_draw_scatter_button(scatter_center, scatter_ready)

func _draw_scatter_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, scatter_radius, Color(0.09, 0.07, 0.13, 0.58))
	draw_arc(center, scatter_radius - 3.0, -PI * 0.5, PI * 1.5, 48, Color(0.66, 0.38, 1.0, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_scatter_cooldown_ratio())
		draw_arc(center, scatter_radius - 3.0, -PI * 0.5, cooldown_angle, 48, Color(0.35, 0.9, 1.0, 0.62), 4.0)
	draw_circle(center, scatter_radius * 0.45, Color(0.47, 0.18, 0.95, base_alpha))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var point := center + Vector2.from_angle(angle) * scatter_radius * 0.68
		draw_circle(point, 3.8, Color(0.72, 0.48, 1.0, 0.9 if ready else 0.28))
	_draw_icon(ICON_SKILL, center, 34.0, 0.95 if ready else 0.35)

func _draw_icon(texture: Texture2D, center: Vector2, icon_size: float, alpha: float) -> void:
	if texture == null:
		return
	var rect := Rect2(center - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
