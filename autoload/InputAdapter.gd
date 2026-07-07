extends Node

var virtual_move: Vector2 = Vector2.ZERO
var virtual_attack_requested: bool = false
var virtual_dash_requested: bool = false
var auto_attack_enabled: bool = true
var dash_cooldown_remaining: float = 0.0

func get_move_vector() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if keyboard.length_squared() > 0.0:
		return keyboard.normalized()
	return virtual_move.limit_length(1.0)

func consume_attack_requested() -> bool:
	var requested := virtual_attack_requested or Input.is_action_pressed("attack")
	virtual_attack_requested = false
	return requested

func consume_dash_requested() -> bool:
	var requested := virtual_dash_requested
	virtual_dash_requested = false
	return requested

func set_virtual_move(value: Vector2) -> void:
	virtual_move = value.limit_length(1.0)

func clear_virtual_move() -> void:
	virtual_move = Vector2.ZERO

func request_virtual_attack() -> void:
	virtual_attack_requested = true

func clear_virtual_attack() -> void:
	virtual_attack_requested = false

func request_virtual_dash() -> void:
	if dash_cooldown_remaining <= 0.0:
		virtual_dash_requested = true

func clear_virtual_dash() -> void:
	virtual_dash_requested = false

func set_dash_cooldown_remaining(value: float) -> void:
	dash_cooldown_remaining = maxf(0.0, value)

func get_dash_cooldown_remaining() -> float:
	return dash_cooldown_remaining

func is_dash_ready() -> bool:
	return dash_cooldown_remaining <= 0.0

func reset_dash_cooldown() -> void:
	dash_cooldown_remaining = 0.0
	clear_virtual_dash()

func set_auto_attack_enabled(value: bool) -> void:
	auto_attack_enabled = value

func is_auto_attack_enabled() -> bool:
	return auto_attack_enabled

func clear_virtual_inputs() -> void:
	clear_virtual_move()
	clear_virtual_attack()
	clear_virtual_dash()
