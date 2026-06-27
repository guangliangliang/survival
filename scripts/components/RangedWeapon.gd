extends Node2D

const WeaponDataResource = preload("res://scripts/data/WeaponData.gd")
const ANIM_FRAME_COUNT := 4
const PLAYER_FRAME_ORIGIN := Vector2(64.0, 86.0)
const VISUAL_SCALE := 0.82
const DIRECTION_DOWN := 0
const DIRECTION_RIGHT := 1
const DIRECTION_UP := 2
const DIRECTION_LEFT := 3
const ARMS_TEXTURE_PIVOT := Vector2(64.0, 64.0)
const MUZZLE_LOCAL := Vector2(47.0, 0.0)
const AIM_SMOOTHING := 18.0
const AIM_PIVOT_POINTS := [
	[Vector2(84, 66), Vector2(84, 64), Vector2(84, 66), Vector2(84, 68)],
	[Vector2(84, 66), Vector2(84, 64), Vector2(84, 66), Vector2(84, 68)],
	[Vector2(84, 66), Vector2(84, 64), Vector2(84, 66), Vector2(84, 68)],
	[Vector2(44, 66), Vector2(44, 64), Vector2(44, 66), Vector2(44, 68)],
]

@export var weapon_data: Resource
@export var bullet_scene: PackedScene
@export var bullet_pool_size: int = 200
@export var firing_enabled: bool = true

@onready var aim_pivot: Node2D = $AimPivot
@onready var arms_rifle_sprite: Sprite2D = $AimPivot/ArmsRifleSprite
@onready var muzzle: Node2D = $AimPivot/Muzzle
@onready var muzzle_flash: Sprite2D = $AimPivot/MuzzleFlash

var runtime_data: Resource
var cooldown: float = 0.0
var bullet_pool: Array[Area2D] = []
var muzzle_flash_timer: float = 0.0
var target_refresh_timer: float = 0.0
var cached_target: Node2D
var aim_direction := Vector2.RIGHT
var aim_target_direction := Vector2.RIGHT
var body_direction_row: int = DIRECTION_DOWN
var body_frame: int = 0

func _ready() -> void:
	if weapon_data == null:
		weapon_data = WeaponDataResource.new()
	runtime_data = weapon_data.duplicate(true)
	rotation = 0.0
	scale = Vector2.ONE
	arms_rifle_sprite.centered = false
	arms_rifle_sprite.offset = -ARMS_TEXTURE_PIVOT
	arms_rifle_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	_build_pool()
	set_body_pose(body_direction_row, body_frame)
	_update_aim_visual()

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	_update_aim()
	_smooth_aim(delta)
	if firing_enabled and cooldown <= 0.0:
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
	muzzle_flash.rotation = 0.0

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

func get_aim_direction() -> Vector2:
	return aim_direction

func refresh_aim_direction() -> void:
	_update_aim()

func has_aim_target() -> bool:
	return is_instance_valid(cached_target) and cached_target.get("is_alive")

func set_body_pose(direction_row: int, frame: int) -> void:
	body_direction_row = clampi(direction_row, DIRECTION_DOWN, DIRECTION_LEFT)
	body_frame = clampi(frame, 0, ANIM_FRAME_COUNT - 1)
	aim_pivot.position = _frame_point_to_local(AIM_PIVOT_POINTS[body_direction_row][body_frame])

func _update_aim() -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	_set_aim_direction((target.global_position - global_position).normalized())

func _set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	aim_target_direction = direction.normalized()

func _smooth_aim(delta: float) -> void:
	var weight := 1.0 - exp(-AIM_SMOOTHING * delta)
	var angle := lerp_angle(aim_direction.angle(), aim_target_direction.angle(), weight)
	aim_direction = Vector2(cos(angle), sin(angle))
	_update_aim_visual()

func _frame_point_to_local(point: Vector2) -> Vector2:
	return (point - PLAYER_FRAME_ORIGIN) * VISUAL_SCALE

func _update_aim_visual() -> void:
	aim_pivot.rotation = aim_direction.angle()
	arms_rifle_sprite.scale = Vector2(VISUAL_SCALE, -VISUAL_SCALE if aim_direction.x < 0.0 else VISUAL_SCALE)
	muzzle.position = MUZZLE_LOCAL
	z_index = 3
