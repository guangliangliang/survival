extends Node2D

@export var drone_texture: Texture2D
@export var bullet_scene: PackedScene
@export var drone_unlocked: bool = false
@export var fixed_offset: Vector2 = Vector2(88.0, -86.0)
@export var fire_rate: float = 1.4
@export var damage: float = 11.0
@export var bullet_speed: float = 620.0
@export var fire_range: float = 560.0
@export var pierce: int = 0
@export var bullet_pool_size: int = 80
@export var sprite_scale: float = 0.027

var cooldown: float = 0.0
var bullet_pool: Array[Area2D] = []
var drones: Array[Node2D] = []
var cached_target: Node2D
var target_refresh_timer: float = 0.0

func _ready() -> void:
	_build_pool()
	_update_drone_visual()

func _process(delta: float) -> void:
	if not drone_unlocked:
		return
	cooldown = maxf(0.0, cooldown - delta)
	target_refresh_timer = maxf(0.0, target_refresh_timer - delta)
	_update_drone_positions()
	if cooldown <= 0.0:
		_fire_volley()

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	match stat_key:
		&"damage_multiplier":
			damage *= 1.0 + amount
		&"fire_rate_multiplier":
			fire_rate *= 1.0 + amount
		&"range_multiplier":
			fire_range *= 1.0 + amount
		&"pierce":
			pierce += int(amount)
		&"drone_unlock":
			drone_unlocked = true
			_update_drone_visual()
		&"drone_damage_multiplier":
			damage *= 1.0 + amount
		&"drone_fire_rate_multiplier":
			fire_rate *= 1.0 + amount
		&"drone_range_multiplier":
			fire_range *= 1.0 + amount

func _build_pool() -> void:
	if bullet_scene == null:
		return
	var owner_node: Node = get_tree().get_first_node_in_group("game_world")
	if owner_node == null:
		owner_node = get_tree().current_scene
	for index in bullet_pool_size:
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.visible = false
		bullet.set("active", false)
		bullet.monitoring = false
		owner_node.add_child.call_deferred(bullet)
		bullet_pool.append(bullet)

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
	for drone in drones:
		drone.position = fixed_offset

func _fire_volley() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	for drone in drones:
		if not is_instance_valid(drone):
			continue
		var bullet := _get_bullet_from_pool()
		if bullet == null:
			break
		var direction := (target.global_position - drone.global_position).normalized()
		bullet.call("activate", drone.global_position, direction, bullet_speed, damage, pierce)
	AudioManager.play_sfx_by_key(&"drone_shot", -3.0)
	cooldown = 1.0 / maxf(fire_rate, 0.1)

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

func _get_bullet_from_pool() -> Area2D:
	for bullet in bullet_pool:
		if is_instance_valid(bullet) and not bullet.get("active"):
			return bullet
	return null
