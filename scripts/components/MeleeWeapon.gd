extends Area2D

@export var damage: float = 20.0
@export var attack_range: float = 80.0
@export var attack_cooldown: float = 0.5
@export var knockback_force: float = 200.0

var attack_timer: Timer = Timer.new()
var can_attack: bool = true
var attack_collision: CollisionShape2D = null

func _ready() -> void:
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	
	attack_collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	attack_collision.shape = shape
	attack_collision.set_deferred("disabled", true)
	add_child(attack_collision)
	
	body_entered.connect(_on_body_entered)

func attack() -> void:
	if not can_attack:
		return
	
	can_attack = false
	attack_timer.start(attack_cooldown)
	attack_collision.set_deferred("disabled", false)
	await get_tree().create_timer(0.2).timeout
	attack_collision.set_deferred("disabled", true)

func _on_attack_cooldown_finished() -> void:
	can_attack = true

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		var health_comp = body.get_node_or_null("HealthComponent")
		if health_comp:
			health_comp.take_damage(damage)
			var direction = (body.global_position - global_position).normalized()
			if body is CharacterBody2D:
				body.velocity += direction * knockback_force
