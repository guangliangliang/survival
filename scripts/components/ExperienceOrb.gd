extends Area2D

var value: int = 1
var active: bool = false
var target: Node2D
var pool_owner: Node
var attraction_radius: float = 180.0
var attraction_speed: float = 420.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(target):
		target = GameManager.player
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= attraction_radius:
			global_position = global_position.move_toward(target.global_position, attraction_speed * delta)
		if distance <= 22.0:
			_collect()

func activate(spawn_position: Vector2, exp_value: int, player: Node2D, owner: Node) -> void:
	global_position = spawn_position
	value = exp_value
	target = player
	pool_owner = owner
	active = true
	visible = true
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)

func _on_body_entered(body: Node) -> void:
	if active and body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if not active:
		return
	GameManager.add_exp(value)
	deactivate()
