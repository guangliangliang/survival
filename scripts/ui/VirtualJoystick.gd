extends Control

const ICON_MOVE := preload("res://assets/images/ui/icons/move.svg")

@export var radius: float = 82.0
@export var knob_radius: float = 34.0

var touch_index: int = -1
var knob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	queue_redraw()

func _exit_tree() -> void:
	InputAdapter.clear_virtual_move()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_update_knob(event.position)
			accept_event()
		elif not event.pressed and event.index == touch_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_knob(event.position)
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				touch_index = -2
				_update_knob(event.position)
			else:
				_release()
	elif event is InputEventMouseMotion and touch_index == -2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_knob(event.position)

func _update_knob(local_position: Vector2) -> void:
	var center := size * 0.5
	knob_offset = (local_position - center).limit_length(radius)
	InputAdapter.set_virtual_move(knob_offset / radius)
	queue_redraw()

func _release() -> void:
	touch_index = -1
	knob_offset = Vector2.ZERO
	InputAdapter.clear_virtual_move()
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.06, 0.075, 0.07, 0.5))
	draw_circle(center, radius - 5.0, Color(0.78, 0.68, 0.38, 0.22), false, 4.0)
	draw_circle(center, radius * 0.48, Color(0.1, 0.12, 0.1, 0.25), false, 2.0)
	draw_circle(center + knob_offset, knob_radius, Color(0.72, 0.78, 0.66, 0.72))
	draw_circle(center + knob_offset, knob_radius - 5.0, Color(0.98, 0.88, 0.52, 0.28), false, 3.0)
	_draw_icon(ICON_MOVE, center + knob_offset, 42.0, 0.72)

func _draw_icon(texture: Texture2D, center: Vector2, icon_size: float, alpha: float) -> void:
	if texture == null:
		return
	var rect := Rect2(center - Vector2(icon_size, icon_size) * 0.5, Vector2(icon_size, icon_size))
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
