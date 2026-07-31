extends Area2D

const MAX_LIFETIME := 4.0

@onready var sprite: Sprite2D = $Sprite2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 480.0
var damage: float = 14.0
var active: bool = false
var max_range: float = 360.0
var life_timer: float = 0.0
var traveled: float = 0.0
var remaining_pierce: int = 0
var hit_ids: Dictionary = {}
var _visual_effects: Node = null

func _get_visual_effects() -> Node:
	if not is_instance_valid(_visual_effects):
		_visual_effects = get_tree().get_first_node_in_group("visual_effects")
	return _visual_effects

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if not active:
		visible = false
		monitoring = false
	set_process(active)

func _process(delta: float) -> void:
	if not active:
		return
	var movement := direction * speed * delta
	global_position += movement
	traveled += movement.length()
	life_timer += delta
	sprite.rotation += delta * 8.0
	queue_redraw()
	if traveled >= max_range or life_timer >= MAX_LIFETIME:
		_deactivate()

func _draw() -> void:
	if not active:
		return
	var pulse := 0.74 + sin(life_timer * 18.0) * 0.16
	draw_line(Vector2(-26.0, 0.0), Vector2(-7.0, 0.0), Color(0.35, 0.9, 1.0, 0.42), 9.0)
	draw_line(Vector2(-18.0, 0.0), Vector2.ZERO, Color(0.78, 0.35, 1.0, 0.5), 5.0)
	draw_circle(Vector2.ZERO, 13.0, Color(0.46, 0.12, 0.95, 0.22 * pulse))

func activate(spawn_position: Vector2, shot_direction: Vector2, shot_speed: float, shot_damage: float, pierce: int, shot_range: float) -> void:
	global_position = spawn_position
	direction = shot_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	sprite.rotation = 0.0
	speed = shot_speed
	damage = shot_damage
	remaining_pierce = pierce
	max_range = shot_range
	life_timer = 0.0
	traveled = 0.0
	hit_ids.clear()
	active = true
	visible = true
	sprite.modulate = Color(0.86, 0.92, 1.0, 0.95)
	set_process(true)
	set_deferred("monitoring", true)

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
			var effects := _get_visual_effects()
			if effects != null:
				effects.call("play_impact", global_position)
			var data = node.get("enemy_data")
			AudioManager.play_sfx_by_key(&"boss_hit" if data != null and data.boss else &"bullet_hit", -4.0)
			node.call("receive_hit", damage, direction)
			if remaining_pierce <= 0:
				_deactivate()
			else:
				remaining_pierce -= 1

func _deactivate() -> void:
	active = false
	visible = false
	set_process(false)
	set_deferred("monitoring", false)
	life_timer = 0.0
	traveled = 0.0
	hit_ids.clear()
