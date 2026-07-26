extends CharacterBody2D

signal released(enemy: Node)

const EnemyDataResource = preload("res://scripts/data/EnemyData.gd")
const ANIM_FRAME_COUNT := 4
const ANIM_ALPHA_THRESHOLD := 0.03
const ANIM_MIN_CONTENT_RUN_WIDTH := 12
const WALK_ANIM_FPS := 8.0
const ATTACK_ANIM_FPS := 9.5
const ATTACK_VISUAL_DURATION := 0.42
const OBSTACLE_AVOIDANCE_LOOKAHEAD := 190.0
const OBSTACLE_AVOIDANCE_PADDING := 62.0
const OBSTACLE_AVOIDANCE_STRENGTH := 1.45
const OBSTACLE_AVOIDANCE_SAMPLES := 6
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

func _ready() -> void:
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
	
	var has_target: bool = is_instance_valid(target)
	
	if has_target:
		var direction := (target.global_position - global_position).normalized()
		var move_direction := _get_obstacle_aware_direction(direction)
		_update_facing(move_direction)
		var distance := global_position.distance_to(target.global_position)
		var was_in_attack_range := in_attack_range
		in_attack_range = distance <= enemy_data.attack_range
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
		move_and_slide()
	
	_update_visual_animation(delta)
	
	if has_target and active_time > 12.0 and global_position.distance_to(target.global_position) > 1550.0 and not enemy_data.boss:
		_release_to_pool()

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

func reset_for_spawn(data: Resource, player_target: Node2D, spawn_position: Vector2, map_node: Node2D = null) -> void:
	enemy_data = data
	target = player_target
	world_map = map_node
	global_position = spawn_position
	is_alive = true
	active_time = 0.0
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

func _get_obstacle_aware_direction(direct_direction: Vector2) -> Vector2:
	if direct_direction.length_squared() <= 0.001 or world_map == null or not world_map.has_method("get_obstacle_block_rects"):
		return direct_direction
	var obstacle_rects: Array = world_map.call("get_obstacle_block_rects")
	if obstacle_rects.is_empty():
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
	for index in OBSTACLE_AVOIDANCE_SAMPLES:
		var ratio := float(index + 1) / float(OBSTACLE_AVOIDANCE_SAMPLES)
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
	if enemy_data.boss and health_component.current_health <= health_component.max_health * 0.5:
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
	if enemy_data.boss and health_component.current_health <= health_component.max_health * 0.5:
		phase_multiplier = 0.65
	attack_timer = enemy_data.attack_cooldown * phase_multiplier

func _perform_attack() -> void:
	if not is_alive:
		return
	attack_count += 1
	
	var direction: Vector2
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = Vector2.RIGHT if not facing_left else Vector2.LEFT
	
	var projectile_pool := get_tree().get_first_node_in_group("enemy_projectile_pool")
	if enemy_data.ranged:
		AudioManager.play_sfx_by_key(_get_ranged_attack_sfx_key())
		if projectile_pool != null:
			projectile_pool.call("fire", global_position, direction, enemy_data.damage, 360.0, enemy_data.projectile_texture)
	elif enemy_data.boss and attack_count % 3 == 0:
		AudioManager.play_sfx_by_key(&"enemy_projectile_pass")
		if projectile_pool != null:
			var projectile_count: int = 14 if health_component.current_health <= health_component.max_health * 0.5 else 10
			projectile_pool.call("fire_radial", global_position, projectile_count, enemy_data.damage * 0.65, 300.0)
	else:
		AudioManager.play_sfx_by_key(&"enemy_melee_swing", -3.0)
		if is_instance_valid(target) and global_position.distance_to(target.global_position) <= enemy_data.attack_range + 28.0:
			var health := target.get_node_or_null("HealthComponent")
			if health:
				health.take_damage(enemy_data.damage)
			var controller := get_tree().get_first_node_in_group("game_controller")
			if controller != null and controller.has_method("shake_camera"):
				controller.call("shake_camera", 4.0 if not enemy_data.boss else 8.0)
	sprite.modulate = Color.WHITE

func receive_hit(amount: float, hit_direction: Vector2) -> void:
	if not is_alive:
		return
	knockback_velocity += hit_direction.normalized() * (45.0 if enemy_data.boss else 110.0)
	health_component.take_damage(amount)
	var feedback := get_tree().get_first_node_in_group("combat_feedback")
	if feedback != null:
		feedback.call("show_damage", global_position, amount)

func _on_health_changed(current_health: float, _max_health: float) -> void:
	if current_health > 0.0 and is_alive:
		flash_timer = 0.1
		sprite.modulate = Color(1.0, 0.2, 0.2)

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	var exp_pool := get_tree().get_first_node_in_group("experience_pool")
	if exp_pool:
		exp_pool.call("spawn_orb", global_position, enemy_data.exp_reward)
	else:
		GameManager.add_exp(enemy_data.exp_reward)
	GameManager.add_kill(enemy_data.boss)
	var effects := get_tree().get_first_node_in_group("visual_effects")
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

func _release_to_pool() -> void:
	if not visible and not is_alive:
		return
	is_alive = false
	visible = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
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
	var using_attack := (in_attack_range or attack_visual_time > 0.0) and enemy_data.attack_texture != null
	var texture: Texture2D = enemy_data.attack_texture if using_attack else enemy_data.walk_texture
	if texture == null:
		return
	if current_animation_texture != texture:
		_set_animation_texture(texture)
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
	var layout := _get_animation_frame_layout(texture)
	var regions: Array = layout["regions"]
	sprite.region_rect = regions[0]
	_apply_sprite_scale(layout["scale_size"])

func _set_animation_frame(frame: int) -> void:
	if current_animation_texture == null:
		return
	var layout := _get_animation_frame_layout(current_animation_texture)
	var regions: Array = layout["regions"]
	sprite.region_rect = regions[clampi(frame, 0, regions.size() - 1)]

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
	var regions: Array = []
	var image := texture.get_image()
	if image != null and image.get_width() > 0 and image.get_height() > 0:
		var content_runs := _find_animation_content_runs(image)
		if content_runs.size() == ANIM_FRAME_COUNT:
			regions = _build_content_gap_regions(content_runs, image.get_width(), image.get_height())
	if regions.is_empty():
		regions = _build_equal_frame_regions(texture.get_width(), texture.get_height())
	return {
		"regions": regions,
		"scale_size": _get_animation_layout_scale_size(regions, texture.get_height()),
	}

func _find_animation_content_runs(image: Image) -> Array:
	var runs: Array = []
	var run_start := -1
	for x in image.get_width():
		if _animation_column_has_content(image, x):
			if run_start < 0:
				run_start = x
		elif run_start >= 0:
			_append_animation_content_run(runs, run_start, x)
			run_start = -1
	if run_start >= 0:
		_append_animation_content_run(runs, run_start, image.get_width())
	return runs

func _animation_column_has_content(image: Image, x: int) -> bool:
	for y in image.get_height():
		if image.get_pixel(x, y).a > ANIM_ALPHA_THRESHOLD:
			return true
	return false

func _append_animation_content_run(runs: Array, start: int, end: int) -> void:
	if end - start >= ANIM_MIN_CONTENT_RUN_WIDTH:
		runs.append(Vector2i(start, end))

func _build_content_gap_regions(content_runs: Array, texture_width: int, texture_height: int) -> Array:
	var boundaries: Array = [0]
	for index in range(ANIM_FRAME_COUNT - 1):
		var left_run: Vector2i = content_runs[index]
		var right_run: Vector2i = content_runs[index + 1]
		var boundary := int(roundf(float(left_run.y + right_run.x) * 0.5))
		boundaries.append(clampi(boundary, 1, texture_width - 1))
	boundaries.append(texture_width)
	return _build_regions_from_boundaries(boundaries, texture_height)

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
	var nominal_width := 1.0
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
