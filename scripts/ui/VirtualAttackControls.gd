extends Control

const ICON_DASH := preload("res://assets/images/ui/icons/dash.svg")
const ICON_SKILL := preload("res://assets/images/ui/icons/skill.svg")
const ICON_SWORD := preload("res://assets/images/ui/icons/arrow.svg")
const ICON_HEAL := preload("res://assets/images/ui/icons/heal.svg")

@export var button_radius: float = 42.0
@export var sword_rain_offset := Vector2(125.0, 166.0)
@export var dash_offset := Vector2(176.0, 106.0)
@export var heal_offset := Vector2(74.0, 106.0)
@export var scatter_offset := Vector2(125.0, 46.0)

func _ready() -> void:
	custom_minimum_size = Vector2(250.0, 210.0)
	set_process(true)
	queue_redraw()

func _exit_tree() -> void:
	InputAdapter.clear_virtual_dash()
	InputAdapter.clear_virtual_scatter()
	InputAdapter.clear_virtual_sword_rain()
	InputAdapter.clear_virtual_heal()

func _process(_delta: float) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_press(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_press(event.position)
		accept_event()

func _handle_press(local_position: Vector2) -> void:
	if _is_inside_sword_rain(local_position):
		InputAdapter.request_virtual_sword_rain()
		queue_redraw()
	elif _is_inside_dash(local_position):
		InputAdapter.request_virtual_dash()
		queue_redraw()
	elif _is_inside_heal(local_position):
		InputAdapter.request_virtual_heal()
		queue_redraw()
	elif _is_inside_scatter(local_position):
		InputAdapter.request_virtual_scatter()
		queue_redraw()

func _is_inside_sword_rain(local_position: Vector2) -> bool:
	return local_position.distance_to(_sword_rain_center()) <= button_radius

func _is_inside_dash(local_position: Vector2) -> bool:
	return local_position.distance_to(_dash_center()) <= button_radius

func _is_inside_heal(local_position: Vector2) -> bool:
	return local_position.distance_to(_heal_center()) <= button_radius

func _is_inside_scatter(local_position: Vector2) -> bool:
	return local_position.distance_to(_scatter_center()) <= button_radius

func _sword_rain_center() -> Vector2:
	return size - sword_rain_offset

func _dash_center() -> Vector2:
	return size - dash_offset

func _heal_center() -> Vector2:
	return size - heal_offset

func _scatter_center() -> Vector2:
	return size - scatter_offset

func _draw() -> void:
	var sword_rain_center := _sword_rain_center()
	var dash_center := _dash_center()
	var heal_center := _heal_center()
	var scatter_center := _scatter_center()
	
	var sword_rain_ready := InputAdapter.is_sword_rain_ready()
	var dash_ready := InputAdapter.is_dash_ready()
	var heal_ready := InputAdapter.is_heal_ready()
	var scatter_ready := InputAdapter.is_scatter_ready()
	
	_draw_sword_rain_button(sword_rain_center, sword_rain_ready)
	_draw_dash_button(dash_center, dash_ready)
	_draw_heal_button(heal_center, heal_ready)
	_draw_scatter_button(scatter_center, scatter_ready)

func _draw_sword_rain_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, button_radius, Color(0.12, 0.08, 0.05, 0.55))
	draw_arc(center, button_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.95, 0.65, 0.3, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_sword_rain_cooldown_ratio())
		draw_arc(center, button_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(1.0, 0.85, 0.4, 0.65), 4.0)
	draw_circle(center, button_radius * 0.55, Color(0.85, 0.55, 0.2, base_alpha))
	_draw_icon(ICON_SWORD, center, 36.0, 0.95 if ready else 0.35)

func _draw_dash_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.72 if ready else 0.2
	draw_circle(center, button_radius, Color(0.08, 0.09, 0.1, 0.52))
	draw_arc(center, button_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.62, 0.74, 0.95, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_dash_cooldown_ratio())
		draw_arc(center, button_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(0.78, 0.9, 1.0, 0.65), 4.0)
	draw_circle(center, button_radius * 0.56, Color(0.3, 0.55, 0.9, base_alpha))
	_draw_icon(ICON_DASH, center, 36.0, 0.95 if ready else 0.35)

func _draw_heal_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, button_radius, Color(0.05, 0.12, 0.08, 0.55))
	draw_arc(center, button_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.35, 0.95, 0.55, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_heal_cooldown_ratio())
		draw_arc(center, button_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(0.5, 1.0, 0.6, 0.65), 4.0)
	draw_circle(center, button_radius * 0.55, Color(0.25, 0.85, 0.4, base_alpha))
	_draw_icon(ICON_HEAL, center, 36.0, 0.95 if ready else 0.35)

func _draw_scatter_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, button_radius, Color(0.09, 0.07, 0.13, 0.58))
	draw_arc(center, button_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.66, 0.38, 1.0, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_scatter_cooldown_ratio())
		draw_arc(center, button_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(0.35, 0.9, 1.0, 0.62), 4.0)
	draw_circle(center, button_radius * 0.55, Color(0.47, 0.18, 0.95, base_alpha))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var point := center + Vector2.from_angle(angle) * button_radius * 0.68
		draw_circle(point, 3.8, Color(0.72, 0.48, 1.0, 0.9 if ready else 0.28))
	_draw_icon(ICON_SKILL, center, 36.0, 0.95 if ready else 0.35)

func _draw_icon(texture: Texture2D, center: Vector2, icon_size: float, alpha: float) -> void:
	if texture == null:
		return
	var rect := Rect2(center - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
