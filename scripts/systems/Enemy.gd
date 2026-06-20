extends CharacterBody2D

signal released(enemy: Node)

@export var enemy_data: EnemyData
@onready var health_component = $HealthComponent
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var target: Node2D
var is_alive: bool = false
var attack_timer: float = 0.0
var flash_timer: float = 0.0
var active_time: float = 0.0

func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	if enemy_data == null:
		enemy_data = EnemyData.new()
	_apply_data()

func _physics_process(delta: float) -> void:
	if not is_alive or not is_instance_valid(target) or not GameManager.run_active:
		velocity = Vector2.ZERO
		return
	active_time += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	var distance := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()
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

func reset_for_spawn(data: EnemyData, player_target: Node2D, spawn_position: Vector2) -> void:
	enemy_data = data
	target = player_target
	global_position = spawn_position
	is_alive = true
	active_time = 0.0
	attack_timer = randf_range(0.0, enemy_data.attack_cooldown)
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
	sprite.color = enemy_data.color
	sprite.offset_left = -enemy_data.size
	sprite.offset_top = -enemy_data.size
	sprite.offset_right = enemy_data.size
	sprite.offset_bottom = enemy_data.size
	var circle := collision_shape.shape as CircleShape2D
	if circle:
		circle.radius = enemy_data.size

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	var health := target.get_node_or_null("HealthComponent")
	if health:
		health.take_damage(enemy_data.damage)
	attack_timer = enemy_data.attack_cooldown

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
	released.emit(self)
