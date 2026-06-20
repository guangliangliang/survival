extends Node2D

@export var orb_scene: PackedScene
@export var pool_size: int = 180

var pool: Array[Area2D] = []

func _ready() -> void:
	add_to_group("experience_pool")
	if orb_scene == null:
		return
	for index in pool_size:
		var orb := orb_scene.instantiate() as Area2D
		add_child(orb)
		orb.call("deactivate")
		pool.append(orb)

func spawn_orb(spawn_position: Vector2, value: int) -> void:
	var orb := _get_free_orb()
	if orb == null:
		# When saturated, award the experience instead of losing progression.
		GameManager.add_exp(value)
		return
	orb.call("activate", spawn_position, value, GameManager.player, self)

func _get_free_orb() -> Area2D:
	for orb in pool:
		if not orb.get("active"):
			return orb
	return null

func get_active_orb_count() -> int:
	var count := 0
	for orb in pool:
		if orb.get("active"):
			count += 1
	return count
