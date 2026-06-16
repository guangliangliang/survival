extends CharacterBody2D

@export var move_speed: float = 100.0
@export var damage: float = 10.0
@export var exp_reward: int = 5
@onready var health_component = $HealthComponent

var target = null
var is_alive: bool = true

func _ready() -> void:
	health_component.died.connect(_on_died)
	target = GameManager.player

func _physics_process(delta: float) -> void:
	if not target or not is_alive:
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

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
