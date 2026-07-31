extends CharacterBody2D

signal released(enemy: Node)

const EnemyDataResource = preload("res://scripts/data/EnemyData.gd")
const ANIM_FRAME_COUNT := 4
const WALK_ANIM_FPS := 8.0
const ATTACK_ANIM_FPS := 9.5
const ATTACK_VISUAL_DURATION := 0.42
const OBSTACLE_AVOIDANCE_LOOKAHEAD := 190.0
const OBSTACLE_AVOIDANCE_PADDING := 62.0
const OBSTACLE_AVOIDANCE_STRENGTH := 1.45
const OBSTACLE_AVOIDANCE_SAMPLES := 6
const OBSTACLE_AVOIDANCE_INTERVAL := 0.08
const MOBILE_OBSTACLE_AVOIDANCE_SAMPLES := 3
const MOBILE_OBSTACLE_AVOIDANCE_INTERVAL := 0.32
const OBSTACLE_AVOIDANCE_SKIP_DISTANCE_SQ := 250000.0
const DESPAWN_DISTANCE_SQ := 2402500.0
const MOBILE_DESPAWN_DISTANCE_SQ := 902500.0
const DESPAWN_MIN_ACTIVE_TIME := 12.0
const MOBILE_DESPAWN_MIN_ACTIVE_TIME := 4.5
const MELEE_ATTACK_PADDING := 28.0
const MOBILE_FAR_LOD_ENTER_DISTANCE_SQ := 360000.0
const MOBILE_FAR_LOD_EXIT_DISTANCE_SQ := 211600.0
const MOBILE_FAR_LOD_ANIMATION_INTERVAL := 0.24
static var animation_frame_layout_cache: Dictionary = {}

@export var enemy_data: Resource
@onready var health_component = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var target: Node2D
var is_alive: bool = false
var attack_timer: float = 0.0
var flash_timer: float = 0.0
var active_time: float = 0.0
var attack_windup: float = 0.0
var attack_visual_time: float = 0.0
var attack_count: int = 0
var knockback_velocity := Vector2.ZERO
var animation_time: float = 0.0
var attack_animation_time: float = 0.0
var in_attack_range: bool = false
var facing_left: bool = false
var current_animation_texture: Texture2D
var world_map: Node2D
var obstacle_avoid_side: float = 1.0
var cached_obstacle_rects: Array = []
var has_world_obstacles: bool = false
var current_frame_index: int = -1
var current_flip_h: bool = false
var avoidance_timer: float = 0.0
var cached_move_direction: Vector2 = Vector2.ZERO
var mobile_performance_mode: bool = false
var obstacle_avoidance_interval: float = OBSTACLE_AVOIDANCE_INTERVAL
var obstacle_avoidance_samples: int = OBSTACLE_AVOIDANCE_SAMPLES
var despawn_distance_sq: float = DESPAWN_DISTANCE_SQ
var despawn_min_active_time: float = DESPAWN_MIN_ACTIVE_TIME
var despawn_check_timer: float = 0.0
var far_lod_active: bool = false
var far_lod_animation_timer: float = 0.0
# 分离算法相关（只用于性能测试）
var use_separation: bool = false
var separation_timer: float = 0.0
var cached_separation_direction: Vector2 = Vector2.ZERO
const SEPARATION_INTERVAL: float = 0.2
const SEPARATION_SCAN_RADIUS_SQ: float = 80.0 * 80.0
const SEPARATION_MAX_TARGETS: int = 5
const SEPARATION_WEIGHT: float = 0.35
var _projectile_pool: Node = null
var _combat_feedback: Node = null
var _experience_pool: Node = null
var _visual_effects: Node = null
var _game_controller: Node = null

const DESPAWN_CHECK_INTERVAL := 0.25

func _get_projectile_pool() -> Node:
	if not is_instance_valid(_projectile_pool):
		_projectile_pool = get_tree().get_first_node_in_group("enemy_projectile_pool")
	return _projectile_pool

func _get_combat_feedback() -> Node:
	if not is_instance_valid(_combat_feedback):
		_combat_feedback = get_tree().get_first_node_in_group("combat_feedback")
	return _combat_feedback

func _get_experience_pool() -> Node:
	if not is_instance_valid(_experience_pool):
		_experience_pool = get_tree().get_first_node_in_group("experience_pool")
	return _experience_pool

func _get_visual_effects() -> Node:
	if not is_instance_valid(_visual_effects):
		_visual_effects = get_tree().get_first_node_in_group("visual_effects")
	return _visual_effects

func _get_game_controller() -> Node:
	if not is_instance_valid(_game_controller):
		_game_controller = get_tree().get_first_node_in_group("game_controller")
	return _game_controller

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	if mobile_performance_mode:
		obstacle_avoidance_interval = MOBILE_OBSTACLE_AVOIDANCE_INTERVAL
		obstacle_avoidance_samples = MOBILE_OBSTACLE_AVOIDANCE_SAMPLES
		despawn_distance_sq = MOBILE_DESPAWN_DISTANCE_SQ
		despawn_min_active_time = MOBILE_DESPAWN_MIN_ACTIVE_TIME
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	if enemy_data == null:
		enemy_data = EnemyDataResource.new()
	_apply_data()

func _physics_process(delta: float) -> void:
	if not is_alive or not GameManager.run_active:
		velocity = Vector2.ZERO
		return
	active_time += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE
	
	var has_target: bool = is_instance_valid(target)
	
	if has_target:
		var target_position := target.global_position
		var to_target := target_position - global_position
		var direction := to_target.normalized()
		var distance_sq := to_target.length_squared()
		var was_in_attack_range := in_attack_range
		in_attack_range = distance_sq <= enemy_data.attack_range * enemy_data.attack_range
		var far_lod := _update_mobile_far_lod(distance_sq)
		if in_attack_range and not was_in_attack_range:
			attack_timer = 0.0
			attack_animation_time = 0.0
			if enemy_data.attack_texture != null:
				_set_animation_texture(enemy_data.attack_texture)
				_set_animation_frame(0)
		if attack_windup > 0.0:
			attack_windup -= delta
			velocity = Vector2.ZERO
			_update_visual_animation(delta)
			if attack_windup <= 0.0:
				_perform_attack()
			return
		if far_lod:
			_update_facing(direction)
			velocity = direction * enemy_data.move_speed
			if knockback_velocity.length_squared() > 1.0:
				velocity += knockback_velocity
				knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			global_position += velocity * delta
			_update_visual_animation(delta)
			_update_despawn_check(delta)
			return
		var move_direction := _get_throttled_move_direction(direction, delta)
		if use_separation and not in_attack_range:
			separation_timer -= delta
			if separation_timer <= 0.0:
				separation_timer = SEPARATION_INTERVAL
				cached_separation_direction = _apply_separation(move_direction)
			move_direction = cached_separation_direction
		_update_facing(move_direction)
		if knockback_velocity.length_squared() > 1.0:
			velocity = move_direction * enemy_data.move_speed + knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			move_and_slide()
			_update_visual_animation(delta)
			return
		if not in_attack_range:
			velocity = move_direction * enemy_data.move_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			_try_attack()
	else:
		_update_mobile_far_lod(0.0)
		if attack_windup > 0.0:
			attack_windup -= delta
			velocity = Vector2.ZERO
			_update_visual_animation(delta)
			if attack_windup <= 0.0:
				_perform_attack()
			return
		if knockback_velocity.length_squared() > 1.0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			move_and_slide()
			_update_visual_animation(delta)
			return
		velocity = Vector2.ZERO
	
	_update_visual_animation(delta)
	_update_despawn_check(delta)

func reset_for_spawn(data: Resource, player_target: Node2D, spawn_position: Vector2, map_node: Node2D = null) -> void:
	enemy_data = data
	target = player_target
	world_map = map_node
	if world_map != null and world_map.has_method("get_obstacle_block_rects"):
		cached_obstacle_rects = world_map.call("get_obstacle_block_rects")
	else:
		cached_obstacle_rects = []
	has_world_obstacles = not cached_obstacle_rects.is_empty()
	avoidance_timer = randf() * obstacle_avoidance_interval
	despawn_check_timer = randf() * DESPAWN_CHECK_INTERVAL
	cached_move_direction = Vector2.ZERO
	# 重置分离算法变量
	use_separation = false
	separation_timer = randf() * SEPARATION_INTERVAL
	cached_separation_direction = Vector2.ZERO
	current_frame_index = -1
	current_flip_h = false
	far_lod_active = false
	far_lod_animation_timer = randf() * MOBILE_FAR_LOD_ANIMATION_INTERVAL
	global_position = spawn_position
	is_alive = true
	active_time = 0.0
	flash_timer = 0.0
	attack_timer = randf_range(0.0, enemy_data.attack_cooldown)
	attack_windup = 0.0
	attack_visual_time = 0.0
	attack_count = 0
	knockback_velocity = Vector2.ZERO
	animation_time = 0.0
	attack_animation_time = 0.0
	in_attack_range = false
	facing_left = false
	obstacle_avoid_side = -1.0 if randf() < 0.5 else 1.0
	current_animation_texture = null
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	collision_layer = 2
	collision_mask = 1
	_apply_data()
	health_component.reset(enemy_data.max_health)

func _update_mobile_far_lod(distance_sq: float) -> bool:
	if not mobile_performance_mode or enemy_data.boss:
		_set_mobile_far_lod(false)
		return false
	if far_lod_active:
		if distance_sq < MOBILE_FAR_LOD_EXIT_DISTANCE_SQ:
			_set_mobile_far_lod(false)
	else:
		if distance_sq > MOBILE_FAR_LOD_ENTER_DISTANCE_SQ:
			_set_mobile_far_lod(true)
	return far_lod_active

func _set_mobile_far_lod(enabled: bool) -> void:
	if far_lod_active == enabled:
		return
	far_lod_active = enabled
	collision_mask = 0 if enabled else 1
	if not enabled:
		avoidance_timer = minf(avoidance_timer, obstacle_avoidance_interval)

func _update_despawn_check(delta: float) -> void:
	if not is_instance_valid(target) or enemy_data.boss or active_time <= despawn_min_active_time:
		return
	despawn_check_timer -= delta
	if despawn_check_timer <= 0.0:
		despawn_check_timer = DESPAWN_CHECK_INTERVAL
		if global_position.distance_squared_to(target.global_position) > despawn_distance_sq:
			_release_to_pool()

func _get_throttled_move_direction(direct_direction: Vector2, delta: float) -> Vector2:
	if not has_world_obstacles:
		return direct_direction
	avoidance_timer -= delta
	if avoidance_timer <= 0.0:
		avoidance_timer = obstacle_avoidance_interval
		cached_move_direction = _get_obstacle_aware_direction(direct_direction)
	if cached_move_direction.length_squared() <= 0.001:
		return direct_direction
	return cached_move_direction

func _get_obstacle_aware_direction(direct_direction: Vector2) -> Vector2:
	if not has_world_obstacles or direct_direction.length_squared() <= 0.001:
		return direct_direction
	var obstacle_rects: Array = cached_obstacle_rects
	if obstacle_rects.is_empty():
		return direct_direction
	if _nearest_obstacle_distance_sq(obstacle_rects) > OBSTACLE_AVOIDANCE_SKIP_DISTANCE_SQ:
		return direct_direction
	var blocking_rect := _get_blocking_obstacle_rect(direct_direction, obstacle_rects)
	if blocking_rect.size == Vector2.ZERO:
		return direct_direction
	var to_obstacle := blocking_rect.get_center() - global_position
	var left_tangent := Vector2(-direct_direction.y, direct_direction.x)
	var right_tangent := Vector2(direct_direction.y, -direct_direction.x)
	var tangent := left_tangent if left_tangent.dot(to_obstacle) < right_tangent.dot(to_obstacle) else right_tangent
	if absf(left_tangent.dot(to_obstacle) - right_tangent.dot(to_obstacle)) < 1.0:
		tangent = left_tangent * obstacle_avoid_side
	var push_away := (global_position - blocking_rect.get_center()).normalized()
	if push_away.length_squared() <= 0.001:
		push_away = tangent
	return (direct_direction + tangent * OBSTACLE_AVOIDANCE_STRENGTH + push_away * 0.45).normalized()

func _nearest_obstacle_distance_sq(obstacle_rects: Array) -> float:
	var nearest_sq := INF
	for rect: Rect2 in obstacle_rects:
		var distance_sq := global_position.distance_squared_to(rect.get_center())
		if distance_sq < nearest_sq:
			nearest_sq = distance_sq
	return nearest_sq

func _get_blocking_obstacle_rect(direct_direction: Vector2, obstacle_rects: Array) -> Rect2:
	var best_rect := Rect2()
	var best_distance_sq := INF
	var lookahead := maxf(OBSTACLE_AVOIDANCE_LOOKAHEAD, enemy_data.size * 6.0)
	for rect: Rect2 in obstacle_rects:
		var expanded_rect := rect.grow(enemy_data.size + OBSTACLE_AVOIDANCE_PADDING)
		if not _path_samples_hit_rect(global_position, direct_direction, lookahead, expanded_rect):
			continue
		var distance_sq := global_position.distance_squared_to(expanded_rect.get_center())
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_rect = expanded_rect
	return best_rect

func _path_samples_hit_rect(origin: Vector2, direction: Vector2, lookahead: float, rect: Rect2) -> bool:
	if rect.has_point(origin):
		return true
	for index in obstacle_avoidance_samples:
		var ratio := float(index + 1) / float(obstacle_avoidance_samples)
		if rect.has_point(origin + direction * lookahead * ratio):
			return true
	return false

func _apply_data() -> void:
	if not is_node_ready():
		return
	sprite.modulate = Color.WHITE if _has_visual_texture() else enemy_data.color
	if enemy_data.walk_texture != null:
		_set_animation_texture(enemy_data.walk_texture)
	elif enemy_data.texture != null:
		sprite.texture = enemy_data.texture
		sprite.region_enabled = false
		var texture_size: Vector2 = sprite.texture.get_size()
		_apply_sprite_scale(texture_size)
	else:
		sprite.texture = null
		sprite.region_enabled = false
		sprite.scale = Vector2.ONE
	var circle := collision_shape.shape as CircleShape2D
	if circle:
		circle.radius = enemy_data.size

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_windup = 0.28 if not enemy_data.boss else 0.48
	attack_visual_time = ATTACK_VISUAL_DURATION if enemy_data.attack_texture != null else attack_windup
	attack_animation_time = 0.0
	if enemy_data.attack_texture != null:
		_set_animation_texture(enemy_data.attack_texture)
		_set_animation_frame(0)
	sprite.modulate = Color.WHITE if enemy_data.attack_texture != null else Color(1.0, 0.72, 0.18)
	var phase_multiplier := 1.0
	if _is_enraged():
		phase_multiplier = 0.65
	attack_timer = enemy_data.attack_cooldown * phase_multiplier

func trigger_attack() -> void:
	if not is_alive or attack_timer > 0.0:
		return
	attack_windup = 0.28 if not enemy_data.boss else 0.48
	attack_visual_time = ATTACK_VISUAL_DURATION if enemy_data.attack_texture != null else attack_windup
	attack_animation_time = 0.0
	if enemy_data.attack_texture != null:
		_set_animation_texture(enemy_data.attack_texture)
		_set_animation_frame(0)
	sprite.modulate = Color.WHITE if enemy_data.attack_texture != null else Color(1.0, 0.72, 0.18)
	var phase_multiplier := 1.0
	if _is_enraged():
		phase_multiplier = 0.65
	attack_timer = enemy_data.attack_cooldown * phase_multiplier

func _is_enraged() -> bool:
	if not enemy_data.boss:
		return false
	var layers: int = max(enemy_data.boss_health_bars, 1)
	return health_component.current_health <= health_component.max_health / float(layers)

func _perform_attack() -> void:
	if not is_alive:
		return
	attack_count += 1
	
	var direction: Vector2
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = Vector2.RIGHT if not facing_left else Vector2.LEFT
	
	var projectile_pool := _get_projectile_pool()
	if enemy_data.ranged:
		AudioManager.play_sfx_by_key(_get_ranged_attack_sfx_key())
		if projectile_pool != null:
			projectile_pool.call("fire", global_position, direction, enemy_data.damage, 360.0, enemy_data.projectile_texture)
	elif enemy_data.boss and attack_count % 3 == 0:
		AudioManager.play_sfx_by_key(&"enemy_projectile_pass")
		if projectile_pool != null:
			var projectile_count: int = 14 if _is_enraged() else 10
			projectile_pool.call("fire_radial", global_position, projectile_count, enemy_data.damage * 0.65, 300.0)
	else:
		AudioManager.play_sfx_by_key(&"enemy_melee_swing", -3.0)
		var padded_attack_range: float = enemy_data.attack_range + MELEE_ATTACK_PADDING
		if is_instance_valid(target) and global_position.distance_squared_to(target.global_position) <= padded_attack_range * padded_attack_range:
			var health := target.get_node_or_null("HealthComponent")
			if health:
				health.take_damage(enemy_data.damage)
			var controller := _get_game_controller()
			if controller != null and controller.has_method("shake_camera"):
				controller.call("shake_camera", 4.0 if not enemy_data.boss else 8.0)
	sprite.modulate = Color.WHITE

func receive_hit(amount: float, hit_direction: Vector2) -> void:
	if not is_alive:
		return
	knockback_velocity += hit_direction.normalized() * (45.0 if enemy_data.boss else 110.0)
	health_component.take_damage(amount)
	var feedback := _get_combat_feedback()
	if feedback != null:
		feedback.call("show_damage", global_position, amount, enemy_data.boss)

func _on_health_changed(current_health: float, _max_health: float) -> void:
	if current_health > 0.0 and is_alive:
		flash_timer = 0.1
		sprite.modulate = Color(1.0, 0.2, 0.2)

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	var exp_pool := _get_experience_pool()
	if exp_pool:
		exp_pool.call("spawn_orb", global_position, enemy_data.exp_reward)
	else:
		GameManager.add_exp(enemy_data.exp_reward)
	GameManager.add_kill(enemy_data.boss)
	var effects := _get_visual_effects()
	if effects != null:
		effects.call("play_death_puff", global_position)
	AudioManager.play_sfx_by_key(&"boss_death" if enemy_data.boss else &"enemy_death")
	_release_to_pool()

func _get_ranged_attack_sfx_key() -> StringName:
	match enemy_data.enemy_id:
		&"thorn_porcupine":
			return &"porcupine_thorn"
		&"cult_wizard":
			return &"wizard_orb"
		_:
			return &"enemy_rifle"

func release_to_pool() -> void:
	_release_to_pool()

func _release_to_pool() -> void:
	if not visible and not is_alive:
		return
	is_alive = false
	visible = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	far_lod_active = false
	set_physics_process(false)
	attack_windup = 0.0
	attack_visual_time = 0.0
	in_attack_range = false
	released.emit(self)

func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > 0.05:
		facing_left = direction.x < 0.0

func _update_visual_animation(delta: float) -> void:
	if not is_node_ready() or not _has_animated_texture():
		return
	if far_lod_active and attack_visual_time <= 0.0 and not in_attack_range:
		far_lod_animation_timer -= delta
		if far_lod_animation_timer > 0.0:
			return
		far_lod_animation_timer = MOBILE_FAR_LOD_ANIMATION_INTERVAL
		delta = MOBILE_FAR_LOD_ANIMATION_INTERVAL
	var using_attack := (in_attack_range or attack_visual_time > 0.0) and enemy_data.attack_texture != null
	var texture: Texture2D = enemy_data.attack_texture if using_attack else enemy_data.walk_texture
	if texture == null:
		return
	if current_animation_texture != texture:
		_set_animation_texture(texture)
	if current_flip_h != facing_left:
		current_flip_h = facing_left
		sprite.flip_h = facing_left
	if using_attack:
		attack_animation_time += delta
		var attack_frame := int(attack_animation_time * ATTACK_ANIM_FPS) % ANIM_FRAME_COUNT
		_set_animation_frame(attack_frame)
		attack_visual_time = maxf(0.0, attack_visual_time - delta)
	else:
		if velocity.length_squared() > 1.0:
			animation_time += delta
		else:
			animation_time = 0.0
		_set_animation_frame(int(animation_time * WALK_ANIM_FPS) % ANIM_FRAME_COUNT)

func _set_animation_texture(texture: Texture2D) -> void:
	current_animation_texture = texture
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.flip_h = facing_left
	current_flip_h = facing_left
	var layout := _get_animation_frame_layout(texture)
	var regions: Array = layout["regions"]
	sprite.region_rect = regions[0]
	current_frame_index = 0
	_apply_sprite_scale(layout["scale_size"])

func _set_animation_frame(frame: int) -> void:
	if current_animation_texture == null:
		return
	var layout := _get_animation_frame_layout(current_animation_texture)
	var regions: Array = layout["regions"]
	var clamped := clampi(frame, 0, regions.size() - 1)
	if clamped == current_frame_index:
		return
	current_frame_index = clamped
	sprite.region_rect = regions[clamped]

func _get_animation_frame_layout(texture: Texture2D) -> Dictionary:
	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())
	if animation_frame_layout_cache.has(cache_key):
		return animation_frame_layout_cache[cache_key]
	var layout := _build_animation_frame_layout(texture)
	animation_frame_layout_cache[cache_key] = layout
	return layout

func _build_animation_frame_layout(texture: Texture2D) -> Dictionary:
	var regions := _build_equal_frame_regions(texture.get_width(), texture.get_height())
	return {
		"regions": regions,
		"scale_size": _get_animation_layout_scale_size(regions, texture.get_height()),
	}

func _build_equal_frame_regions(texture_width: int, texture_height: int) -> Array:
	var boundaries: Array = []
	for index in range(ANIM_FRAME_COUNT + 1):
		boundaries.append(int(roundf(float(index * texture_width) / float(ANIM_FRAME_COUNT))))
	return _build_regions_from_boundaries(boundaries, texture_height)

func _build_regions_from_boundaries(boundaries: Array, texture_height: int) -> Array:
	var regions: Array = []
	for index in range(ANIM_FRAME_COUNT):
		var left: int = boundaries[index]
		var right: int = boundaries[index + 1]
		regions.append(Rect2(Vector2(left, 0.0), Vector2(maxi(1, right - left), texture_height)))
	return regions

func _get_animation_layout_scale_size(regions: Array, texture_height: int) -> Vector2:
	var widths: Array = []
	for region: Rect2 in regions:
		widths.append(region.size.x)
	widths.sort()
	var nominal_width: float = 1.0
	if not widths.is_empty():
		var middle := int(widths.size() / 2)
		if widths.size() % 2 == 0 and middle > 0:
			nominal_width = (widths[middle - 1] + widths[middle]) * 0.5
		else:
			nominal_width = widths[middle]
	return Vector2(maxf(1.0, nominal_width), maxf(1.0, float(texture_height)))

func _apply_sprite_scale(texture_size: Vector2) -> void:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		sprite.scale = Vector2.ONE
		return
	var target_size: Vector2 = Vector2.ONE * enemy_data.size * 2.4 * enemy_data.visual_scale_multiplier
	sprite.scale = Vector2.ONE * minf(target_size.x / texture_size.x, target_size.y / texture_size.y)

func _has_visual_texture() -> bool:
	return enemy_data.texture != null or _has_animated_texture()

func _has_animated_texture() -> bool:
	return enemy_data.walk_texture != null or enemy_data.attack_texture != null

func _apply_separation(direct_direction: Vector2) -> Vector2:
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if not is_instance_valid(enemy_spawner):
		return direct_direction
	
	var separation_direction: Vector2 = Vector2.ZERO
	var nearby_count: int = 0
	
	for enemy in enemy_spawner.get_active_enemies():
		if not is_instance_valid(enemy) or enemy == self:
			continue
		var delta_pos: Vector2 = global_position - enemy.global_position
		var dist_sq: float = delta_pos.length_squared()
		if dist_sq > SEPARATION_SCAN_RADIUS_SQ:
			continue
		if dist_sq < 1.0:
			dist_sq = 1.0
		var weight: float = 1.0 / dist_sq
		separation_direction += delta_pos.normalized() * weight
		nearby_count += 1
		if nearby_count >= SEPARATION_MAX_TARGETS:
			break
	
	if nearby_count == 0:
		return direct_direction
	
	separation_direction = separation_direction.normalized()
	return (direct_direction * (1.0 - SEPARATION_WEIGHT) + separation_direction * SEPARATION_WEIGHT).normalized()
