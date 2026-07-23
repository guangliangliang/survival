extends Area2D

var target_position: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var damage: float = 20.0
var active: bool = false
var lifetime: float = 2.0
var life_timer: float = 0.0
var hit_ids: Dictionary = {}
var fall_duration: float = 0.4

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if not active:
		return
	
	life_timer += delta
	var progress: float = minf(life_timer / fall_duration, 1.0)
	var ease_progress: float = ease_out_cubic(progress)
	global_position = start_position.lerp(target_position, ease_progress)
	
	var base_rotation: float = (target_position - start_position).angle() + PI * 0.25
	rotation = lerp(rotation, base_rotation, delta * 15.0)
	
	if life_timer >= lifetime:
		_deactivate()

func ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)

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
			var effects := get_tree().get_first_node_in_group("visual_effects")
			if effects != null:
				effects.call("play_impact", global_position)
			var data = node.get("enemy_data")
			AudioManager.play_sfx_by_key(&"boss_hit" if data != null and data.boss else &"bullet_hit")
			node.call("receive_hit", damage, Vector2.DOWN)
			_deactivate()

func activate(spawn_position: Vector2, target_pos: Vector2, shot_damage: float) -> void:
	start_position = spawn_position
	target_position = target_pos
	global_position = spawn_position
	damage = shot_damage
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
