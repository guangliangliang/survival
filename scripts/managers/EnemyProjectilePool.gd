extends Node2D

@export var projectile_scene: PackedScene
@export var pool_size: int = 160
var pool: Array[Area2D] = []

func _ready() -> void:
	add_to_group("enemy_projectile_pool")
	if projectile_scene == null:
		return
	for index in pool_size:
		var projectile := projectile_scene.instantiate() as Area2D
		add_child(projectile)
		projectile.call("deactivate")
		pool.append(projectile)

func fire(spawn_position: Vector2, direction: Vector2, damage: float, speed: float = 330.0) -> bool:
	for projectile in pool:
		if not projectile.get("active"):
			projectile.call("activate", spawn_position, direction, damage, speed)
			return true
	return false

func fire_radial(spawn_position: Vector2, count: int, damage: float, speed: float = 280.0) -> void:
	for index in count:
		fire(spawn_position, Vector2.from_angle(TAU * float(index) / float(count)), damage, speed)

func get_active_count() -> int:
	var count := 0
	for projectile in pool:
		if projectile.get("active"):
			count += 1
	return count
