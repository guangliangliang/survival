extends CharacterBody2D

signal released(enemy: Node)

const EnemyDataResource = preload("res://scripts/data/EnemyData.gd")
const ANIM_FRAME_COUNT := 4
const WALK_ANIM_FPS := 8.0
const ATTACK_ANIM_FPS := 9.5
const ATTACK_VISUAL_DURATION := 0.42

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

func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	if enemy_data == null:
		enemy_data = EnemyDataResource.new()
	_apply_data()

func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(target) or not GameManager.run_active:
		velocity = Vector2.ZERO
		return
	active_time += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	var direction := (target.global_position - global_position).normalized()
	_update_facing(direction)
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
		velocity = direction * enemy_data.move_speed + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		_update_visual_animation(delta)
		return
	if not in_attack_range:
		velocity = direction * enemy_data.move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_try_attack()
	_update_visual_animation(delta)
	if active_time > 12.0 and distance > 1550.0 and not enemy_data.boss:
		_release_to_pool()

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			sprite.modulate = Color.WHITE

func reset_for_spawn(data: Resource, player_target: Node2D, spawn_position: Vector2) -> void:
	enemy_data = data
	target = player_target
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
	current_animation_texture = null
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	collision_layer = 2
	collision_mask = 1
	_apply_data()
	health_component.reset(enemy_data.max_health)

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

func _perform_attack() -> void:
	if not is_instance_valid(target) or not is_alive:
		return
	attack_count += 1
	var direction := (target.global_position - global_position).normalized()
	var projectile_pool := get_tree().get_first_node_in_group("enemy_projectile_pool")
	if enemy_data.ranged:
		if projectile_pool != null:
			projectile_pool.call("fire", global_position, direction, enemy_data.damage, 360.0, enemy_data.projectile_texture)
	elif enemy_data.boss and attack_count % 3 == 0:
		if projectile_pool != null:
			var projectile_count: int = 14 if health_component.current_health <= health_component.max_health * 0.5 else 10
			projectile_pool.call("fire_radial", global_position, projectile_count, enemy_data.damage * 0.65, 300.0)
	else:
		if global_position.distance_to(target.global_position) <= enemy_data.attack_range + 28.0:
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
	_release_to_pool()

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
	var frame_size := _get_animation_frame_size(texture)
	sprite.region_rect = Rect2(Vector2.ZERO, frame_size)
	_apply_sprite_scale(frame_size)

func _set_animation_frame(frame: int) -> void:
	if current_animation_texture == null:
		return
	var frame_size := _get_animation_frame_size(current_animation_texture)
	sprite.region_rect = Rect2(Vector2(frame * frame_size.x, 0.0), frame_size)

func _get_animation_frame_size(texture: Texture2D) -> Vector2:
	return Vector2(texture.get_width() / ANIM_FRAME_COUNT, texture.get_height())

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
