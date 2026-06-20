extends Node2D

const WeaponDataResource = preload("res://scripts/data/WeaponData.gd")

@export var weapon_data: Resource
@export var bullet_scene: PackedScene
@export var bullet_pool_size: int = 200

var runtime_data: Resource
var cooldown: float = 0.0
var bullet_pool: Array[Area2D] = []

func _ready() -> void:
	if weapon_data == null:
		weapon_data = WeaponDataResource.new()
	runtime_data = weapon_data.duplicate(true)
	_build_pool()

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	if cooldown <= 0.0:
		fire()

func _build_pool() -> void:
	if bullet_scene == null:
		return
	var owner_node := get_tree().get_first_node_in_group("game_world")
	if owner_node == null:
		owner_node = get_tree().current_scene
	for index in bullet_pool_size:
		var bullet := bullet_scene.instantiate() as Area2D
		bullet.visible = false
		bullet.set("active", false)
		bullet.monitoring = false
		owner_node.add_child.call_deferred(bullet)
		bullet_pool.append(bullet)

func fire() -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var base_direction := (target.global_position - global_position).normalized()
	var count := maxi(1, runtime_data.projectile_count)
	for index in count:
		var bullet := _get_bullet_from_pool()
		if bullet == null:
			break
		var offset := float(index) - float(count - 1) * 0.5
		var direction := base_direction.rotated(deg_to_rad(offset * runtime_data.spread_degrees))
		bullet.call("activate", global_position, direction, runtime_data.bullet_speed, runtime_data.damage, runtime_data.pierce)
	cooldown = 1.0 / maxf(runtime_data.fire_rate, 0.1)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_distance_sq: float = runtime_data.fire_range * runtime_data.fire_range
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or not node.get("is_alive"):
			continue
		var distance_sq := global_position.distance_squared_to(node.global_position)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			nearest = node as Node2D
	return nearest

func _get_bullet_from_pool() -> Area2D:
	for bullet in bullet_pool:
		if is_instance_valid(bullet) and not bullet.get("active"):
			return bullet
	return null

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	match stat_key:
		&"damage_multiplier":
			runtime_data.damage *= 1.0 + amount
		&"fire_rate_multiplier":
			runtime_data.fire_rate *= 1.0 + amount
		&"range_multiplier":
			runtime_data.fire_range *= 1.0 + amount
		&"projectile_count":
			runtime_data.projectile_count += int(amount)
		&"pierce":
			runtime_data.pierce += int(amount)

func get_active_bullet_count() -> int:
	var count := 0
	for bullet in bullet_pool:
		if is_instance_valid(bullet) and bullet.get("active"):
			count += 1
	return count
