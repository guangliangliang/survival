extends Node

var virtual_move: Vector2 = Vector2.ZERO

func get_move_vector() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if keyboard.length_squared() > 0.0:
		return keyboard.normalized()
	return virtual_move.limit_length(1.0)

func set_virtual_move(value: Vector2) -> void:
	virtual_move = value.limit_length(1.0)

func clear_virtual_move() -> void:
	virtual_move = Vector2.ZERO
