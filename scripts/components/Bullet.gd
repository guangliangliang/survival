extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 10.0
var active: bool = false
var lifetime: float = 3.0
var life_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not active:
		return
	
	global_position += direction * speed * delta
	life_timer += delta
	
	if life_timer >= lifetime:
		_deactivate()

func _on_body_entered(body: Node) -> void:
	if not active:
		return
	
	if body.is_in_group("enemy"):
		var health_comp = body.get_node_or_null("HealthComponent")
		if health_comp:
			health_comp.take_damage(damage)
		_deactivate()

func _deactivate() -> void:
	active = false
	visible = false
	life_timer = 0.0
