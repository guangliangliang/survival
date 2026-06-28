extends Node2D

@export var flywheel_texture: Texture2D
@export var flywheel_count: int = 0
@export var orbit_radius: float = 92.0
@export var spin_speed: float = 5.2
@export var damage: float = 9.0
@export var hit_interval: float = 0.38
@export var hit_radius: float = 20.0
@export var sprite_scale: float = 0.021

var orbit_angle: float = 0.0
var hit_cooldowns: Dictionary = {}
var flywheels: Array[Area2D] = []

func _ready() -> void:
	_rebuild_flywheels()

func _process(delta: float) -> void:
	if flywheel_count <= 0:
		return
	orbit_angle += spin_speed * delta
	for id in hit_cooldowns.keys():
		hit_cooldowns[id] = maxf(0.0, float(hit_cooldowns[id]) - delta)
	_update_flywheel_positions()
	_check_overlaps()

func apply_upgrade(stat_key: StringName, amount: float) -> void:
	match stat_key:
		&"damage_multiplier":
			damage *= 1.0 + amount
		&"fire_rate_multiplier":
			hit_interval /= 1.0 + amount
			spin_speed *= 1.0 + amount * 0.5
		&"range_multiplier":
			orbit_radius *= 1.0 + amount
		&"flywheel_count":
			flywheel_count += int(amount)
			_rebuild_flywheels()

func _rebuild_flywheels() -> void:
	for flywheel in flywheels:
		if is_instance_valid(flywheel):
			flywheel.queue_free()
	flywheels.clear()
	for index in maxi(0, flywheel_count):
		var area := Area2D.new()
		area.name = "Flywheel%d" % (index + 1)
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitoring = true
		area.monitorable = false

		var sprite := Sprite2D.new()
		sprite.texture = flywheel_texture
		sprite.centered = true
		sprite.scale = Vector2.ONE * sprite_scale
		sprite.z_index = 4
		area.add_child(sprite)

		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = hit_radius
		collision.shape = circle
		area.add_child(collision)

		add_child(area)
		flywheels.append(area)
	_update_flywheel_positions()

func _update_flywheel_positions() -> void:
	if flywheels.is_empty():
		return
	for index in flywheels.size():
		var angle := orbit_angle + TAU * float(index) / float(flywheels.size())
		var flywheel := flywheels[index]
		flywheel.position = Vector2.from_angle(angle) * orbit_radius
		flywheel.rotation += spin_speed * 3.0 * get_process_delta_time()

func _check_overlaps() -> void:
	for flywheel in flywheels:
		if not is_instance_valid(flywheel):
			continue
		for body in flywheel.get_overlapping_bodies():
			_try_hit(body, flywheel.global_position)

func _try_hit(node: Node, hit_position: Vector2) -> void:
	if not (node is Node2D) or not node.is_in_group("enemy") or not node.get("is_alive"):
		return
	var target := node as Node2D
	var id := node.get_instance_id()
	if float(hit_cooldowns.get(id, 0.0)) > 0.0:
		return
	hit_cooldowns[id] = hit_interval
	var direction := (target.global_position - global_position).normalized()
	if direction.length_squared() <= 0.001:
		direction = (target.global_position - hit_position).normalized()
	if node.has_method("receive_hit"):
		node.call("receive_hit", damage, direction)
		AudioManager.play_sfx_by_key(&"flywheel_hit", -2.0)
	var effects := get_tree().get_first_node_in_group("visual_effects")
	if effects != null:
		effects.call("play_impact", hit_position)
