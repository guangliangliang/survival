extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 10.0
var active: bool = false
var lifetime: float = 3.0
var life_timer: float = 0.0
var remaining_pierce: int = 0
var hit_ids: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if not active:
		return
	
	global_position += direction * speed * delta
	life_timer += delta
	
	if life_timer >= lifetime:
		_deactivate()

func _on_body_entered(body: Node) -> void:
	_check_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_check_hit(area.get_parent())

func _check_hit(node: Node) -> void:
	if not active:
		return
	
	if node.is_in_group("enemy") and not hit_ids.has(node.get_instance_id()):
		if node.has_method("receive_hit"):
			hit_ids[node.get_instance_id()] = true
			node.call("receive_hit", damage, direction)
			if remaining_pierce <= 0:
				_deactivate()
			else:
				remaining_pierce -= 1

func activate(spawn_position: Vector2, shot_direction: Vector2, shot_speed: float, shot_damage: float, pierce: int) -> void:
	global_position = spawn_position
	direction = shot_direction.normalized()
	speed = shot_speed
	damage = shot_damage
	remaining_pierce = pierce
	hit_ids.clear()
	life_timer = 0.0
	active = true
	visible = true
	set_deferred("monitoring", true)

func _deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)
	life_timer = 0.0
	hit_ids.clear()
