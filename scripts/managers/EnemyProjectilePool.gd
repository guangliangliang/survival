extends Node2D

@export var projectile_scene: PackedScene
@export var pool_size: int = 160
@export var mobile_pool_size: int = 96
@export var projectile_visual_scale_multiplier: float = 1.0
var pool: Array[Area2D] = []
var _cursor: int = 0

func _ready() -> void:
	add_to_group("enemy_projectile_pool")
	if GameManager.is_mobile_performance_profile():
		pool_size = mini(pool_size, mobile_pool_size)
	if projectile_scene == null:
		return
	for index in pool_size:
		var projectile := projectile_scene.instantiate() as Area2D
		projectile.set("visual_scale_multiplier", projectile_visual_scale_multiplier)
		add_child(projectile)
		projectile.call("deactivate")
		pool.append(projectile)

func fire(spawn_position: Vector2, direction: Vector2, damage: float, speed: float = 330.0, texture: Texture2D = null) -> bool:
	var count := pool.size()
	if count == 0:
		return false
	for offset in count:
		var index := (_cursor + offset) % count
		var projectile := pool[index]
		if not projectile.get("active"):
			projectile.call("activate", spawn_position, direction, damage, speed, texture)
			_cursor = (index + 1) % count
			return true
	return false

func fire_radial(spawn_position: Vector2, count: int, damage: float, speed: float = 280.0, texture: Texture2D = null) -> void:
	count = maxi(1, count)
	for index in count:
		fire(spawn_position, Vector2.from_angle(TAU * float(index) / float(count)), damage, speed, texture)

func fire_arc(spawn_position: Vector2, direction: Vector2, count: int, arc_degrees: float, damage: float, speed: float = 280.0, texture: Texture2D = null) -> void:
	count = maxi(1, count)
	var shot_direction := direction.normalized()
	if shot_direction.length_squared() <= 0.001:
		shot_direction = Vector2.RIGHT
	if count == 1:
		fire(spawn_position, shot_direction, damage, speed, texture)
		return
	var arc := deg_to_rad(clampf(absf(arc_degrees), 0.0, 360.0))
	var center_angle := shot_direction.angle()
	var start_angle := center_angle - arc * 0.5
	for index in count:
		var ratio := float(index) / float(count - 1)
		fire(spawn_position, Vector2.from_angle(start_angle + arc * ratio), damage, speed, texture)

func get_active_count() -> int:
	var count := 0
	for projectile in pool:
		if projectile.get("active"):
			count += 1
	return count
