extends CharacterBody2D

@export var move_speed: float = 100.0
@export var damage: float = 10.0
@export var exp_reward: int = 5
@onready var health_component = $HealthComponent
@onready var sprite = $Sprite2D

var target = null
var is_alive: bool = true
var is_flashing = false
var flash_timer = 0.0
var flash_duration = 0.1
var original_modulate = Color(1, 1, 1, 1)

func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	target = GameManager.player
	original_modulate = sprite.modulate

func _physics_process(delta: float) -> void:
	if not target or not is_alive:
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _process(delta: float):
	if is_flashing:
		flash_timer += delta
		if flash_timer >= flash_duration:
			is_flashing = false
			sprite.modulate = original_modulate

func _on_health_changed(current_health: float, max_health: float):
	if current_health < max_health:
		_flash()

func _flash():
	is_flashing = true
	flash_timer = 0.0
	sprite.modulate = Color(1, 0, 0, 1)

func _on_died() -> void:
	is_alive = false
	GameManager.add_exp(exp_reward)
	GameManager.add_kill()
	await get_tree().process_frame
	queue_free()

func _on_body_entered(body):
	if not is_alive:
		return
	if body.is_in_group("player"):
		var health_comp = body.get_node_or_null("HealthComponent")
		if health_comp:
			health_comp.take_damage(damage)
