extends CharacterBody2D

signal released(enemy: Node)

const EnemyDataResource = preload("res://scripts/data/EnemyData.gd")

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
var attack_count: int = 0
var knockback_velocity := Vector2.ZERO

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
	if attack_windup > 0.0:
		attack_windup -= delta
		velocity = Vector2.ZERO
		if attack_windup <= 0.0:
			_perform_attack()
		return
	var distance := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()
	if knockback_velocity.length_squared() > 1.0:
		velocity = direction * enemy_data.move_speed + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		return
	if distance > enemy_data.attack_range:
		velocity = direction * enemy_data.move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_try_attack()
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
	attack_count = 0
	knockback_velocity = Vector2.ZERO
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
	sprite.texture = enemy_data.texture
	sprite.modulate = Color.WHITE if enemy_data.texture != null else enemy_data.color
	if sprite.texture != null:
		var texture_size: Vector2 = sprite.texture.get_size()
		var target_size: Vector2 = Vector2.ONE * enemy_data.size * 2.4
		sprite.scale = Vector2.ONE * minf(target_size.x / texture_size.x, target_size.y / texture_size.y)
	else:
		sprite.scale = Vector2.ONE
	var circle := collision_shape.shape as CircleShape2D
	if circle:
		circle.radius = enemy_data.size

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_windup = 0.28 if not enemy_data.boss else 0.48
	sprite.modulate = Color(1.0, 0.72, 0.18)
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
			projectile_pool.call("fire", global_position, direction, enemy_data.damage, 360.0)
	elif enemy_data.boss and attack_count % 3 == 0:
		if projectile_pool != null:
			var projectile_count := 14 if health_component.current_health <= health_component.max_health * 0.5 else 10
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
	released.emit(self)
