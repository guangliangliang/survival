extends Control

const ICON_DASH := preload("res://assets/images/ui/icons/dash.svg")
const ICON_SKILL := preload("res://assets/images/ui/icons/skill.svg")
const ICON_LASER := preload("res://assets/images/ui/icons/laser_sweep.svg")
const ICON_SWORD := preload("res://assets/images/ui/icons/arrow.svg")
const ICON_HEAL := preload("res://assets/images/ui/icons/heal.svg")
const ICON_ARROW := preload("res://assets/images/ui/icons/arrow.svg")

const MOUSE_TOUCH_INDEX := -2

@export var attack_radius: float = 66.0
@export var skill_radius: float = 40.0
@export var auto_radius: float = 22.0
@export var attack_offset := Vector2(110.0, 90.0)
@export var auto_offset := Vector2(22.0, 155.0)
@export var sword_rain_offset := Vector2(110.0, 250.0)
@export var dash_offset := Vector2(202.0, 221.0)
@export var heal_offset := Vector2(260.0, 145.0)
@export var scatter_offset := Vector2(265.0, 49.0)

@export var sword_rain_aim_scale: float = 6.0

var _attack_touch_index: int = -1
var _attack_press_time: float = 0.0
var _auto_flash_time: float = 0.0
var _sword_rain_touch_index: int = -1
var _sword_rain_press_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(360.0, 360.0)
	set_process(true)
	queue_redraw()

func _exit_tree() -> void:
	InputAdapter.set_attack_held(false)
	InputAdapter.clear_virtual_dash()
	InputAdapter.clear_virtual_scatter()
	InputAdapter.clear_virtual_sword_rain()
	InputAdapter.clear_virtual_heal()

func _process(delta: float) -> void:
	if _attack_press_time > 0.0:
		_attack_press_time = maxf(0.0, _attack_press_time - delta)
	if _auto_flash_time > 0.0:
		_auto_flash_time = maxf(0.0, _auto_flash_time - delta)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position, event.index)
		else:
			_handle_release(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		_handle_drag(event.position, event.index)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(event.position, MOUSE_TOUCH_INDEX)
		else:
			_handle_release(MOUSE_TOUCH_INDEX)
		accept_event()
	elif event is InputEventMouseMotion and _attack_touch_index == MOUSE_TOUCH_INDEX:
		_handle_drag(event.position, MOUSE_TOUCH_INDEX)

func _handle_press(local_position: Vector2, touch_index: int) -> void:
	if _is_inside_sword_rain(local_position):
		if touch_index == MOUSE_TOUCH_INDEX:
			InputAdapter.request_virtual_sword_rain()
			return
		InputAdapter.begin_virtual_sword_rain_aim()
		if InputAdapter.is_virtual_sword_rain_aiming():
			_sword_rain_touch_index = touch_index
			_sword_rain_press_position = local_position
			InputAdapter.set_virtual_sword_rain_aim_offset(Vector2.ZERO)
		return
	if _is_inside_dash(local_position):
		InputAdapter.request_virtual_dash()
		return
	if _is_inside_heal(local_position):
		InputAdapter.request_virtual_heal()
		return
	if _is_inside_scatter(local_position):
		InputAdapter.request_virtual_scatter()
		return
	if _is_inside_auto(local_position):
		InputAdapter.toggle_auto_attack()
		_auto_flash_time = 0.18
		return
	if _is_inside_attack(local_position):
		_attack_touch_index = touch_index
		_attack_press_time = 0.08
		InputAdapter.set_attack_held(true)

func _handle_release(touch_index: int) -> void:
	if _sword_rain_touch_index == touch_index:
		_sword_rain_touch_index = -1
		InputAdapter.confirm_virtual_sword_rain_aim()
		return
	if _attack_touch_index == touch_index:
		_attack_touch_index = -1
		InputAdapter.set_attack_held(false)

func _handle_drag(local_position: Vector2, touch_index: int) -> void:
	if _sword_rain_touch_index == touch_index:
		var offset := (local_position - _sword_rain_press_position) * sword_rain_aim_scale
		InputAdapter.set_virtual_sword_rain_aim_offset(offset)
		return
	if _attack_touch_index != touch_index:
		return
	if not _is_inside_attack(local_position):
		_attack_touch_index = -1
		InputAdapter.set_attack_held(false)

func _is_inside_attack(local_position: Vector2) -> bool:
	return local_position.distance_to(_attack_center()) <= attack_radius

func _is_inside_auto(local_position: Vector2) -> bool:
	return local_position.distance_to(_auto_center()) <= auto_radius

func _is_inside_sword_rain(local_position: Vector2) -> bool:
	return local_position.distance_to(_sword_rain_center()) <= skill_radius

func _is_inside_dash(local_position: Vector2) -> bool:
	return local_position.distance_to(_dash_center()) <= skill_radius

func _is_inside_heal(local_position: Vector2) -> bool:
	return local_position.distance_to(_heal_center()) <= skill_radius

func _is_inside_scatter(local_position: Vector2) -> bool:
	return local_position.distance_to(_scatter_center()) <= skill_radius

func _attack_center() -> Vector2:
	return size - attack_offset

func _auto_center() -> Vector2:
	return size - auto_offset

func _sword_rain_center() -> Vector2:
	return size - sword_rain_offset

func _dash_center() -> Vector2:
	return size - dash_offset

func _heal_center() -> Vector2:
	return size - heal_offset

func _scatter_center() -> Vector2:
	return size - scatter_offset

func _draw() -> void:
	_draw_sword_rain_button(_sword_rain_center(), InputAdapter.is_sword_rain_ready())
	_draw_dash_button(_dash_center(), InputAdapter.is_dash_ready())
	_draw_heal_button(_heal_center(), InputAdapter.is_heal_ready())
	_draw_scatter_button(_scatter_center(), InputAdapter.is_scatter_ready())
	_draw_attack_button(_attack_center(), _attack_touch_index != -1)
	_draw_auto_button(_auto_center(), InputAdapter.is_auto_attack_enabled())

func _draw_attack_button(center: Vector2, pressed: bool) -> void:
	var press_ratio := 0.0
	if pressed:
		press_ratio = 1.0
	elif _attack_press_time > 0.0:
		press_ratio = _attack_press_time / 0.08
	var radius := attack_radius * (1.0 - 0.06 * press_ratio)
	draw_circle(center, radius + 4.0, Color(0.05, 0.02, 0.02, 0.55))
	draw_circle(center, radius, Color(0.14, 0.05, 0.04, 0.78))
	draw_arc(center, radius - 4.0, -PI * 0.5, PI * 1.5, 64, Color(1.0, 0.55, 0.2, 0.85), 4.0)
	var inner_color := Color(0.95, 0.32, 0.18, 0.82) if pressed else Color(0.82, 0.24, 0.14, 0.72)
	draw_circle(center, radius * 0.62, inner_color)
	if pressed:
		draw_arc(center, radius - 2.0, 0.0, TAU, 72, Color(1.0, 0.85, 0.45, 0.9), 2.5)
	_draw_icon(ICON_SKILL, center, 50.0, 0.98)

func _draw_auto_button(center: Vector2, enabled: bool) -> void:
	var flash := 0.0
	if _auto_flash_time > 0.0:
		flash = _auto_flash_time / 0.18
	if enabled:
		var ring_color := Color(1.0, 0.72, 0.28, 0.85).lerp(Color(1.0, 1.0, 0.9, 1.0), flash)
		draw_circle(center, auto_radius + 3.0, Color(0.1, 0.06, 0.02, 0.55))
		draw_circle(center, auto_radius, Color(0.95, 0.55, 0.18, 0.78))
		draw_arc(center, auto_radius - 2.0, -PI * 0.5, PI * 1.5, 40, ring_color, 2.5)
		var t := Time.get_ticks_msec() / 1000.0
		var dash_start := t * 1.8
		for index in 8:
			var a0 := dash_start + TAU * float(index) / 8.0
			var a1 := a0 + TAU / 16.0
			draw_arc(center, auto_radius + 5.0, a0, a1, 8, Color(1.0, 0.85, 0.4, 0.55), 1.8)
		_draw_icon(ICON_ARROW, center, 24.0, 1.0)
	else:
		draw_circle(center, auto_radius + 3.0, Color(0.05, 0.05, 0.06, 0.5))
		draw_circle(center, auto_radius, Color(0.22, 0.24, 0.28, 0.72))
		draw_arc(center, auto_radius - 2.0, -PI * 0.5, PI * 1.5, 40, Color(0.55, 0.6, 0.65, 0.7), 2.0)
		_draw_icon(ICON_ARROW, center, 24.0, 0.35)
		var slash_dir := Vector2(1.0, -1.0).normalized() * (auto_radius - 2.0)
		draw_line(center - slash_dir, center + slash_dir, Color(0.9, 0.35, 0.32, 0.85), 3.0)

func _draw_sword_rain_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, skill_radius, Color(0.12, 0.08, 0.05, 0.55))
	draw_arc(center, skill_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.95, 0.65, 0.3, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_sword_rain_cooldown_ratio())
		draw_arc(center, skill_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(1.0, 0.85, 0.4, 0.65), 4.0)
	draw_circle(center, skill_radius * 0.55, Color(0.85, 0.55, 0.2, base_alpha))
	_draw_icon(ICON_SWORD, center, 34.0, 0.95 if ready else 0.35)

func _draw_dash_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.72 if ready else 0.2
	draw_circle(center, skill_radius, Color(0.08, 0.09, 0.1, 0.52))
	draw_arc(center, skill_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.62, 0.74, 0.95, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_dash_cooldown_ratio())
		draw_arc(center, skill_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(0.78, 0.9, 1.0, 0.65), 4.0)
	draw_circle(center, skill_radius * 0.56, Color(0.3, 0.55, 0.9, base_alpha))
	_draw_icon(ICON_DASH, center, 34.0, 0.95 if ready else 0.35)

func _draw_heal_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, skill_radius, Color(0.05, 0.12, 0.08, 0.55))
	draw_arc(center, skill_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(0.35, 0.95, 0.55, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_heal_cooldown_ratio())
		draw_arc(center, skill_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(0.5, 1.0, 0.6, 0.65), 4.0)
	draw_circle(center, skill_radius * 0.55, Color(0.25, 0.85, 0.4, base_alpha))
	_draw_icon(ICON_HEAL, center, 34.0, 0.95 if ready else 0.35)

func _draw_scatter_button(center: Vector2, ready: bool) -> void:
	var base_alpha := 0.58 if ready else 0.28
	var accent_alpha := 0.78 if ready else 0.2
	draw_circle(center, skill_radius, Color(0.13, 0.08, 0.04, 0.58))
	draw_arc(center, skill_radius - 4.0, -PI * 0.5, PI * 1.5, 48, Color(1.0, 0.66, 0.24, accent_alpha), 4.0)
	if not ready:
		var cooldown_angle := -PI * 0.5 + TAU * (1.0 - InputAdapter.get_scatter_cooldown_ratio())
		draw_arc(center, skill_radius - 4.0, -PI * 0.5, cooldown_angle, 48, Color(1.0, 0.85, 0.4, 0.62), 4.0)
	draw_circle(center, skill_radius * 0.55, Color(0.95, 0.54, 0.15, base_alpha))
	_draw_icon(ICON_LASER, center, 34.0, 0.95 if ready else 0.35)

func _draw_icon(texture: Texture2D, center: Vector2, icon_size: float, alpha: float) -> void:
	if texture == null:
		return
	var rect := Rect2(center - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
