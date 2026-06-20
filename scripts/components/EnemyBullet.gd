extends Area2D

var direction := Vector2.RIGHT
var speed: float = 330.0
var damage: float = 10.0
var active: bool = false
var life_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not active:
		return
	global_position += direction * speed * delta
	life_timer += delta
	if life_timer >= 4.0:
		deactivate()

func activate(spawn_position: Vector2, shot_direction: Vector2, shot_damage: float, shot_speed: float = 330.0) -> void:
	global_position = spawn_position
	direction = shot_direction.normalized()
	damage = shot_damage
	speed = shot_speed
	life_timer = 0.0
	active = true
	visible = true
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)

func _on_body_entered(body: Node) -> void:
	if not active or not body.is_in_group("player"):
		return
	var health := body.get_node_or_null("HealthComponent")
	if health != null:
		health.take_damage(damage)
	var controller := get_tree().get_first_node_in_group("game_controller")
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", 5.0)
	deactivate()
