extends Node2D

const WeaponDataResource = preload("res://scripts/data/WeaponData.gd")

@export var weapon_data: Resource
@export var bullet_scene: PackedScene
@export var bullet_pool_size: int = 200

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var muzzle: Node2D = $Muzzle
@onready var muzzle_flash: Sprite2D = $MuzzleFlash

var runtime_data: Resource
var cooldown: float = 0.0
var bullet_pool: Array[Area2D] = []
var muzzle_flash_timer: float = 0.0
var target_refresh_timer: float = 0.0
var cached_target: Node2D
var aim_direction := Vector2.RIGHT

func _ready() -> void:
	if weapon_data == null:
		weapon_data = WeaponDataResource.new()
	runtime_data = weapon_data.duplicate(true)
	_build_pool()

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	_update_aim()
	if cooldown <= 0.0:
		fire()
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		_update_muzzle_flash()
		queue_redraw()
	elif muzzle_flash.visible:
		muzzle_flash.visible = false
	target_refresh_timer = maxf(0.0, target_refresh_timer - delta)

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

func fire() -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	var base_direction: Vector2 = (target.global_position - global_position).normalized()
	_set_aim_direction(base_direction)
	var count: int = maxi(1, runtime_data.projectile_count)
	for index in count:
		var bullet: Area2D = _get_bullet_from_pool()
		if bullet == null:
			break
		var offset: float = float(index) - float(count - 1) * 0.5
		var direction: Vector2 = base_direction.rotated(deg_to_rad(offset * runtime_data.spread_degrees))
		bullet.call("activate", muzzle.global_position, direction, runtime_data.bullet_speed, runtime_data.damage, runtime_data.pierce)
	muzzle_flash_timer = 0.06
	muzzle_flash.visible = true
	_update_muzzle_flash()
	queue_redraw()
	cooldown = 1.0 / maxf(runtime_data.fire_rate, 0.1)

func _find_nearest_enemy() -> Node2D:
	if target_refresh_timer > 0.0 and is_instance_valid(cached_target) and cached_target.get("is_alive"):
		if global_position.distance_squared_to(cached_target.global_position) <= runtime_data.fire_range * runtime_data.fire_range:
			return cached_target
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner != null and spawner.has_method("get_nearest_enemy"):
		cached_target = spawner.call("get_nearest_enemy", global_position, runtime_data.fire_range)
	else:
		cached_target = null
	target_refresh_timer = 0.08
	return cached_target

func _draw() -> void:
	if muzzle_flash_timer > 0.0:
		draw_circle(to_local(muzzle.global_position), 7.0, Color(1.0, 0.78, 0.18, muzzle_flash_timer / 0.06))

func _update_muzzle_flash() -> void:
	var frame: int = clampi(2 - int(ceil(muzzle_flash_timer / 0.06 * 3.0)), 0, 2)
	muzzle_flash.region_rect = Rect2(frame * 32, 0, 32, 32)
	muzzle_flash.position = muzzle.position

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

func _update_aim() -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	_set_aim_direction((target.global_position - global_position).normalized())

func _set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	aim_direction = direction
	rotation = aim_direction.angle()
	scale.y = -1.0 if aim_direction.x < 0.0 else 1.0
	z_index = -1 if aim_direction.y < -0.35 else 1
