extends Node

var virtual_move: Vector2 = Vector2.ZERO
var virtual_attack_requested: bool = false
var auto_attack_enabled: bool = true

func get_move_vector() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if keyboard.length_squared() > 0.0:
		return keyboard.normalized()
	return virtual_move.limit_length(1.0)

func consume_attack_requested() -> bool:
	var requested := virtual_attack_requested or Input.is_action_pressed("attack")
	virtual_attack_requested = false
	return requested

func set_virtual_move(value: Vector2) -> void:
	virtual_move = value.limit_length(1.0)

func clear_virtual_move() -> void:
	virtual_move = Vector2.ZERO

func request_virtual_attack() -> void:
	virtual_attack_requested = true

func clear_virtual_attack() -> void:
	virtual_attack_requested = false

func set_auto_attack_enabled(value: bool) -> void:
	auto_attack_enabled = value

func is_auto_attack_enabled() -> bool:
	return auto_attack_enabled

func clear_virtual_inputs() -> void:
	clear_virtual_move()
	clear_virtual_attack()
