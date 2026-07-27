extends Node2D

@export var drone_texture: Texture2D
@export var drone_unlocked: bool = false
@export var fixed_offset: Vector2 = Vector2(88.0, -86.0)
@export var damage: float = 22.0
@export var fire_range: float = 300.0
@export var sprite_scale: float = 0.027
@export var hover_radius: Vector2 = Vector2(24.0, 14.0)
@export var hover_speed: float = 2.2
@export var laser_width: float = 14.0
@export var laser_hit_interval: float = 0.15

var drones: Array[Node2D] = []
var cached_target: Node2D
var target_refresh_timer: float = 0.0
var hover_angle: float = 0.0
var upgrade_level: int = 0
var laser_target: Node2D
var laser_clock: float = 0.0
var laser_next_hit: Dictionary = {}

func _ready() -> void:
	_update_drone_visual()

func _process(delta: float) -> void:
	if not drone_unlocked:
		return
	target_refresh_timer = maxf(0.0, target_refresh_timer - delta)
	hover_angle = wrapf(hover_angle + hover_speed * delta, 0.0, TAU)
	_update_drone_positions()
	_update_laser(delta)

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	match stat_key:
		&"damage_multiplier":
			damage *= 1.0 + amount
		&"range_multiplier":
			fire_range *= 1.0 + amount
		&"drone_damage_multiplier":
			damage *= 1.0 + amount
		&"drone_range_multiplier":
			fire_range *= 1.0 + amount
		&"drone_unlock":
			drone_unlocked = true
			_update_drone_visual()
		&"drone_upgrade":
			upgrade_level += int(amount)
			match upgrade_level:
				1:
					drone_unlocked = true
					_update_drone_visual()
				2:
					damage *= 1.3
					fire_range *= 1.25
				3:
					laser_hit_interval *= 0.8
					fire_range *= 1.25
				4:
					laser_width *= 2.0
					fire_range *= 1.3
				5:
					damage *= 1.3
					laser_hit_interval *= 0.8
					fire_range *= 1.3

func _update_drone_visual() -> void:
	for drone in drones:
		if is_instance_valid(drone):
			drone.queue_free()
	drones.clear()
	if not drone_unlocked:
		return
	var drone := Node2D.new()
	drone.name = "Drone"
	var sprite := Sprite2D.new()
	sprite.texture = drone_texture
	sprite.centered = true
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.z_index = 5
	drone.add_child(sprite)
	add_child(drone)
	drones.append(drone)
	_update_drone_positions()

func _update_drone_positions() -> void:
	if drones.is_empty():
		return
	for index in drones.size():
		var angle := hover_angle + TAU * float(index) / float(drones.size())
		var offset := Vector2(cos(angle) * hover_radius.x, sin(angle) * hover_radius.y)
		drones[index].position = fixed_offset + offset

func _draw() -> void:
	if not is_instance_valid(laser_target):
		return
	for drone in drones:
		if not is_instance_valid(drone):
			continue
		_draw_laser_beam(drone.position, to_local(laser_target.global_position))

func _draw_laser_beam(from: Vector2, to: Vector2) -> void:
	var half := laser_width * 0.5
	var dir := (to - from).normalized()
	var side := dir.orthogonal()
	var taper := 0.35

	var outer := PackedVector2Array([
		from + side * half * 1.5,
		to + side * half * taper,
		to - side * half * taper,
		from - side * half * 1.5,
	])
	draw_colored_polygon(outer, Color(0.2, 0.6, 1.0, 0.15))

	var core := PackedVector2Array([
		from + side * half,
		to + side * half * taper,
		to - side * half * taper,
		from - side * half,
	])
	draw_colored_polygon(core, Color(0.4, 0.85, 1.0, 0.6))

	var thin := PackedVector2Array([
		from + side * half * 0.3,
		to + side * half * 0.15 * taper,
		to - side * half * 0.15 * taper,
		from - side * half * 0.3,
	])
	draw_colored_polygon(thin, Color(1.0, 1.0, 1.0, 0.85))

func _update_laser(delta: float) -> void:
	laser_clock += delta
	laser_target = _find_nearest_enemy()
	if not is_instance_valid(laser_target):
		queue_redraw()
		return
	for drone in drones:
		if not is_instance_valid(drone):
			continue
		var dir := (laser_target.global_position - drone.global_position).normalized()
		_apply_laser_damage(laser_target, dir)
	queue_redraw()

func _apply_laser_damage(enemy: Node2D, direction: Vector2) -> void:
	var eid := enemy.get_instance_id()
	if laser_next_hit.has(eid) and laser_clock < laser_next_hit[eid]:
		return
	laser_next_hit[eid] = laser_clock + laser_hit_interval
	if enemy.has_method("receive_hit"):
		enemy.call("receive_hit", damage * laser_hit_interval, direction)

func _find_nearest_enemy() -> Node2D:
	if target_refresh_timer > 0.0 and is_instance_valid(cached_target) and cached_target.get("is_alive"):
		if global_position.distance_squared_to(cached_target.global_position) <= fire_range * fire_range:
			return cached_target
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner != null and spawner.has_method("get_nearest_enemy"):
		cached_target = spawner.call("get_nearest_enemy", global_position, fire_range)
	else:
		cached_target = null
	target_refresh_timer = 0.08
	return cached_target
