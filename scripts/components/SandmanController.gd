extends Node2D

const SAND := Color("d9a64d")
const SAND_LIGHT := Color("ffe19a")
const SAND_DARK := Color("7b4a20")

var active := false
var blade_mode := false
var attack_cooldown := 0.0
var fissure_cooldown := 0.0
var tornado_cooldown := 0.0
var cave_cooldown := 0.0
var fissure_time := 0.0
var fissure_direction := Vector2.RIGHT
var tornadoes: Array[Dictionary] = []
var sand_balls: Array[Dictionary] = []
var cave_time := 0.0
var cave_center := Vector2.ZERO
var cave_tick := 0.0
var cave_targeting := false
var cave_virtual_targeting := false
var damage_multiplier := 1.0
var attack_speed_multiplier := 1.0
var upgrade_levels := {&"sand_fissure_level": 0, &"sand_tornado_level": 0, &"sand_cave_level": 0}
var spawner: Node

@onready var player := get_parent().get_parent() as Node2D

func set_active(value: bool) -> void:
	active = value
	visible = value
	if not value:
		cave_targeting = false
	queue_redraw()

func _ready() -> void:
	set_active(GameManager.selected_character != null and GameManager.selected_character.combat_profile == &"sandman")

func _process(delta: float) -> void:
	if not active:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	fissure_cooldown = maxf(0.0, fissure_cooldown - delta)
	tornado_cooldown = maxf(0.0, tornado_cooldown - delta)
	cave_cooldown = maxf(0.0, cave_cooldown - delta)
	fissure_time = maxf(0.0, fissure_time - delta)
	cave_time = maxf(0.0, cave_time - delta)
	_update_tornadoes(delta)
	_update_sand_balls(delta)
	_update_cave(delta)
	_update_virtual_cave_targeting()
	if InputAdapter.consume_sand_toggle_requested():
		blade_mode = not blade_mode
		AudioManager.play_sfx_by_key(&"sand_blade" if blade_mode else &"sand_ball", -5.0)
	if InputAdapter.is_auto_attack_enabled() or InputAdapter.is_attack_held():
		_try_attack()
	if InputAdapter.consume_scatter_requested():
		_cast_fissure()
	if InputAdapter.consume_sword_rain_requested():
		_cast_tornadoes()
	if InputAdapter.consume_lightning_storm_requested():
		if cave_targeting:
			_confirm_cave()
		else:
			cave_targeting = cave_cooldown <= 0.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if active and cave_targeting and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_confirm_cave()
		get_viewport().set_input_as_handled()

func _try_attack() -> void:
	if attack_cooldown > 0.0:
		return
	var target := _nearest(560.0)
	if target == null:
		return
	var direction := (target.global_position - player.global_position).normalized()
	if blade_mode:
		attack_cooldown = 0.5 / attack_speed_multiplier
		for enemy in _enemies():
			var offset: Vector2 = enemy.global_position - player.global_position
			if offset.length() <= 86.0 and absf(direction.angle_to(offset.normalized())) <= deg_to_rad(50.0):
				_hit(enemy, 36.0, direction, 330.0)
		AudioManager.play_sfx_by_key(&"sand_blade", -5.0)
	else:
		attack_cooldown = 0.2 / attack_speed_multiplier
		var muzzle := player.global_position + Vector2(34.0, -22.0) + direction * 18.0
		sand_balls.append({"position": muzzle, "direction": direction, "time": 560.0 / 680.0, "damage": 18.0, "hit": false})
		AudioManager.play_sfx_by_key(&"sand_ball", -8.0)

func _cast_fissure() -> void:
	if fissure_cooldown > 0.0:
		return
	fissure_cooldown = 7.0
	fissure_time = 0.42
	fissure_direction = _aim_direction()
	var level: int = upgrade_levels[&"sand_fissure_level"]
	var width := 52.0 + 9.0 * level
	for enemy in _enemies():
		var offset: Vector2 = enemy.global_position - player.global_position
		var forward := offset.dot(fissure_direction)
		if forward >= 0.0 and forward <= 320.0 and absf(offset.dot(fissure_direction.orthogonal())) <= width * 0.5:
			_hit(enemy, 65.0 * (1.0 + 0.16 * level), fissure_direction, 250.0)
			enemy.apply_slow(0.60 - 0.04 * level, 1.5)
	AudioManager.play_sfx_by_key(&"sand_fissure", -3.0)

func _cast_tornadoes() -> void:
	if tornado_cooldown > 0.0:
		return
	tornado_cooldown = 11.0
	var level: int = upgrade_levels[&"sand_tornado_level"]
	for index in 8:
		tornadoes.append({"position": player.global_position, "direction": Vector2.from_angle(TAU * index / 8.0), "time": 1.8 + 0.2 * level, "damage": 30.0 * (1.0 + 0.15 * level), "hit": {}})
	AudioManager.play_sfx_by_key(&"sand_tornado", -3.0)

func _confirm_cave() -> void:
	if cave_cooldown > 0.0:
		return
	cave_targeting = false
	cave_center = get_global_mouse_position() if not cave_virtual_targeting else player.global_position + InputAdapter.get_virtual_lightning_storm_aim_offset()
	cave_time = 5.0 + 0.5 * int(upgrade_levels[&"sand_cave_level"])
	cave_tick = 0.0
	cave_cooldown = 14.0
	AudioManager.play_sfx_by_key(&"sand_cave", -3.0)

func _update_virtual_cave_targeting() -> void:
	if InputAdapter.is_virtual_lightning_storm_aiming():
		cave_virtual_targeting = true
		cave_targeting = cave_cooldown <= 0.0
	elif cave_virtual_targeting:
		cave_virtual_targeting = false
		if InputAdapter.consume_virtual_lightning_storm_cast():
			_confirm_cave()

func _update_tornadoes(delta: float) -> void:
	for tornado in tornadoes:
		tornado.time -= delta
		tornado.position += tornado.direction * 115.0 * delta
		for enemy in _enemies():
			if tornado.position.distance_squared_to(enemy.global_position) <= 42.0 * 42.0 and not tornado.hit.has(enemy.get_instance_id()):
				tornado.hit[enemy.get_instance_id()] = true
				_hit(enemy, tornado.damage, tornado.direction, 190.0)
				enemy.apply_slow(0.65, 1.2)
	tornadoes = tornadoes.filter(func(t): return t.time > 0.0)

func _update_sand_balls(delta: float) -> void:
	for ball in sand_balls:
		ball.time -= delta
		ball.position += ball.direction * 680.0 * delta
		for enemy in _enemies():
			if is_instance_valid(enemy) and enemy.get("is_alive") and ball.position.distance_squared_to(enemy.global_position) <= 18.0 * 18.0:
				_hit(enemy, ball.damage, ball.direction, 110.0)
				ball.hit = true
				break
	sand_balls = sand_balls.filter(func(ball): return ball.time > 0.0 and not ball.hit)

func _update_cave(delta: float) -> void:
	if cave_time <= 0.0:
		return
	cave_tick -= delta
	if cave_tick > 0.0:
		return
	cave_tick = 0.5
	var level: int = upgrade_levels[&"sand_cave_level"]
	var radius := 130.0 + 12.0 * level
	for enemy in _enemies():
		if cave_center.distance_squared_to(enemy.global_position) <= radius * radius:
			_hit(enemy, 18.0 * (1.0 + 0.12 * level), (enemy.global_position - cave_center).normalized(), 70.0)
			enemy.apply_slow(0.50, 0.7)

func _enemies() -> Array:
	if not is_instance_valid(spawner):
		spawner = get_tree().get_first_node_in_group("enemy_spawner")
	return spawner.get_active_enemies() if spawner != null and spawner.has_method("get_active_enemies") else get_tree().get_nodes_in_group("enemy")

func _nearest(range: float) -> Node2D:
	var best: Node2D
	var best_distance := range * range
	for enemy in _enemies():
		if is_instance_valid(enemy) and enemy.get("is_alive"):
			var distance := player.global_position.distance_squared_to(enemy.global_position)
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best

func _aim_direction() -> Vector2:
	var target := _nearest(560.0)
	return (target.global_position - player.global_position).normalized() if target != null else Vector2.RIGHT

func _hit(enemy: Node2D, damage: float, direction: Vector2, knockback: float) -> void:
	if enemy != null and enemy.has_method("receive_hit"):
		enemy.receive_hit(damage * damage_multiplier, direction)
		enemy.knockback_velocity += direction * knockback

func apply_upgrade(key: StringName, amount: float) -> void:
	if upgrade_levels.has(key):
		upgrade_levels[key] += int(amount)
	elif key == &"damage_multiplier":
		damage_multiplier *= 1.0 + amount
	elif key == &"fire_rate_multiplier":
		attack_speed_multiplier *= 1.0 + amount

func _draw() -> void:
	if not active:
		return
	var t := Time.get_ticks_msec() * 0.001
	var bob := sin(t * 2.4) * 3.0
	draw_circle(Vector2(0, -28 + bob), 31.0, SAND_DARK)
	draw_circle(Vector2(0, -31 + bob), 27.0, SAND)
	draw_circle(Vector2(-9, -40 + bob), 7.0, SAND_LIGHT)
	for side in [-1.0, 1.0]:
		var hand := Vector2(side * (45.0 + sin(t * 2.0 + side) * 4.0), -23.0 + cos(t * 2.6 + side) * 6.0)
		draw_circle(hand, 13.0, SAND_DARK)
		draw_circle(hand, 10.0, SAND)
	var aim := _aim_direction()
	if blade_mode:
		draw_line(Vector2(31.0, -22.0), Vector2(31.0, -22.0) + aim * 48.0, SAND_LIGHT, 8.0)
	else:
		draw_circle(Vector2(34.0, -22.0) + aim * 13.0, 9.0, SAND_LIGHT)
	for ball in sand_balls:
		var p := to_local(ball.position)
		var tail: Vector2 = -ball.direction * 24.0
		draw_line(p + tail, p, Color(SAND, 0.4), 7.0)
		draw_circle(p, 9.0, SAND_DARK)
		draw_circle(p, 6.0, SAND_LIGHT)
	if fissure_time > 0.0:
		draw_line(Vector2.ZERO, fissure_direction * 320.0, SAND_DARK, 58.0)
		draw_line(Vector2.ZERO, fissure_direction * 320.0, SAND_LIGHT, 12.0)
	for tornado in tornadoes:
		var p := to_local(tornado.position)
		draw_arc(p, 26.0, 0.0, TAU, 18, SAND, 5.0)
		draw_arc(p, 14.0, t * 8.0, t * 8.0 + PI * 1.5, 12, SAND_LIGHT, 3.0)
	if cave_time > 0.0:
		var c := to_local(cave_center)
		draw_circle(c, 130.0 + 12.0 * int(upgrade_levels[&"sand_cave_level"]), Color(SAND_DARK, 0.35))
		draw_arc(c, 130.0, 0.0, TAU, 40, SAND, 3.0)
	if cave_targeting:
		var c := to_local(get_global_mouse_position())
		draw_arc(c, 130.0, 0.0, TAU, 40, SAND_LIGHT, 3.0)
