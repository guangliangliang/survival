extends Container
class_name TouchScrollContainer

## 抖音式触摸拖动滚动容器。
## 修复微信小游戏中 ScrollContainer 触摸拖动只能滑一下、无法继续上下滚动的问题。
## 完全自行接管触摸/鼠标拖动，直接偏移唯一子节点，带惯性与回弹阻尼，不依赖内建滚动逻辑。
##
## 注意：使用 _input 全局捕获触摸事件，而不是 _gui_input。
## 因为子控件（卡片/图标/开关/滑块）默认 mouse_filter=STOP 会先吃掉触摸事件，
## 导致 _gui_input 收不到、微信里滚动失效。改用 _input 判断落点后再处理，
## 且只有真正拖动超过阈值才 accept_event()，从而不影响点击子控件。

const DRAG_THRESHOLD := 6.0
const INERTIA_FRICTION := 9.0
const MIN_VELOCITY := 6.0
const WHEEL_STEP := 64.0

var _content: Control
var _scroll: float = 0.0
var _max_scroll: float = 0.0

var _touch_index: int = -1
var _tracking: bool = false
var _dragging: bool = false
var _last_y: float = 0.0
var _press_y: float = 0.0
var _velocity: float = 0.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func _get_content() -> Control:
	for child in get_children():
		if child is Control:
			return child
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

func _sort_children() -> void:
	_content = _get_content()
	if _content == null:
		_max_scroll = 0.0
		return
	var content_min := _content.get_combined_minimum_size()
	var content_height := maxf(content_min.y, size.y)
	fit_child_in_rect(_content, Rect2(0.0, -_scroll, size.x, content_height))
	_max_scroll = maxf(content_height - size.y, 0.0)
	_clamp_scroll()

func _clamp_scroll() -> void:
	_scroll = clampf(_scroll, 0.0, _max_scroll)
	if _content != null:
		_content.position.y = -_scroll

func _is_inside(global_pos: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().has_point(global_pos)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and _is_inside(event.position):
				_begin_track(event.index, event.position.y)
		elif event.index == _touch_index:
			var was_dragging := _dragging
			_end_track()
			if was_dragging:
				accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_drag(event.position.y)
		if _dragging:
			accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed and _is_inside(event.position):
			_apply_scroll(-WHEEL_STEP)
			_velocity = 0.0
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed and _is_inside(event.position):
			_apply_scroll(WHEEL_STEP)
			_velocity = 0.0
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _touch_index == -1 and _is_inside(event.position):
				_begin_track(-2, event.position.y)
			elif not event.pressed and _touch_index == -2:
				var was_dragging := _dragging
				_end_track()
				if was_dragging:
					accept_event()
	elif event is InputEventMouseMotion and _touch_index == -2:
		_update_drag(event.position.y)
		if _dragging:
			accept_event()

func _begin_track(index: int, y: float) -> void:
	_touch_index = index
	_tracking = true
	_dragging = false
	_last_y = y
	_press_y = y
	_velocity = 0.0

func _update_drag(y: float) -> void:
	if not _tracking:
		return
	var delta := y - _last_y
	_last_y = y
	if not _dragging:
		if absf(y - _press_y) < DRAG_THRESHOLD:
			return
		_dragging = true
	_apply_scroll(-delta)
	_velocity = -delta / maxf(get_process_delta_time(), 0.0001)

func _end_track() -> void:
	_tracking = false
	_touch_index = -1
	if not _dragging:
		_velocity = 0.0
	_dragging = false

func _apply_scroll(amount: float) -> void:
	_scroll += amount
	_clamp_scroll()

func _process(delta: float) -> void:
	if _tracking or absf(_velocity) < MIN_VELOCITY:
		_velocity = 0.0
		return
	_apply_scroll(_velocity * delta)
	if _scroll <= 0.0 or _scroll >= _max_scroll:
		_velocity = 0.0
		return
	_velocity = lerpf(_velocity, 0.0, clampf(INERTIA_FRICTION * delta, 0.0, 1.0))
