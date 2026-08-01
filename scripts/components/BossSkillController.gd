extends Node2D

const TYPE_CHARGE := &"charge"
const TYPE_SLAM := &"slam"
const TYPE_RADIAL := &"radial_projectiles"
const TYPE_FAN := &"fan_projectiles"
const TYPE_SUMMON := &"summon"

const STATE_IDLE := &"idle"
const STATE_WINDUP := &"windup"
const STATE_CHARGE := &"charge"
const STATE_RECOVERY := &"recovery"

const TELEGRAPH_FILL := Color(1.0, 0.25, 0.08, 0.18)
const TELEGRAPH_EDGE := Color(1.0, 0.68, 0.24, 0.74)
const IMPACT_FILL := Color(1.0, 0.9, 0.42, 0.16)
const IMPACT_EDGE := Color(1.0, 0.72, 0.24, 0.82)
const MOBILE_SUMMON_LIMIT := 2

var enemy: CharacterBody2D
var target: Node2D
var cooldowns: Dictionary = {}
var current_skill: Resource = null
var state: StringName = STATE_IDLE
var state_timer: float = 0.0
var cast_direction := Vector2.RIGHT
var charge_has_hit: bool = false
var impact_flash_time: float = 0.0
var mobile_performance_mode: bool = false
var forced_skill_cursor: int = 0

func _ready() -> void:
	visible = false
	z_index = 35
	mobile_performance_mode = GameManager.is_mobile_performance_profile()

func configure(owner_enemy: CharacterBody2D) -> void:
	enemy = owner_enemy
	target = null
	cooldowns.clear()
	current_skill = null
	state = STATE_IDLE
	state_timer = 0.0
	cast_direction = Vector2.RIGHT
	charge_has_hit = false
	impact_flash_time = 0.0
	forced_skill_cursor = 0
	visible = false
	queue_redraw()

func cancel() -> void:
	current_skill = null
	state = STATE_IDLE
	state_timer = 0.0
	charge_has_hit = false
	impact_flash_time = 0.0
	visible = false
	queue_redraw()

func is_busy() -> bool:
	return current_skill != null and state != STATE_IDLE

func process_skill(delta: float, target_node: Node2D, direction: Vector2, distance_sq: float) -> bool:
	_update_cooldowns(delta)
	_update_impact_flash(delta)
	target = target_node
	if not _has_skills():
		return false
	if is_busy():
		_update_active_skill(delta)
		return true
	if not is_instance_valid(target):
		return false
	var distance := sqrt(maxf(distance_sq, 0.0))
	var skill := _find_usable_skill(distance)
	if skill == null:
		return false
	_start_skill(skill, direction)
	return true

func force_skill(target_node: Node2D) -> bool:
	if not _has_skills() or is_busy() or not is_instance_valid(enemy):
		return false
	target = target_node
	if not is_instance_valid(target):
		target = enemy.get("target")
	if not is_instance_valid(target):
		return false
	var direction := (target.global_position - enemy.global_position).normalized()
	if direction.length_squared() <= 0.001:
		direction = _get_facing_direction()
	var skill := _find_forced_skill()
	if skill == null:
		return false
	_start_skill(skill, direction)
	return true

func get_debug_text() -> String:
	if not _has_skills():
		return "Skills: none"
	var lines := PackedStringArray()
	lines.append("Phase %d" % _get_current_phase())
	if is_busy() and current_skill != null:
		lines.append("%s %s %.1fs" % [current_skill.display_name, String(state), state_timer])
	else:
		for skill in _get_skill_list():
			if skill == null or int(skill.min_phase) > _get_current_phase():
				continue
			var cd := float(cooldowns.get(skill.skill_id, 0.0))
			lines.append("%s %.1fs" % [skill.display_name, cd])
	return " | ".join(lines)

func _update_active_skill(delta: float) -> void:
	if current_skill == null or not is_instance_valid(enemy):
		cancel()
		return
	match state:
		STATE_WINDUP:
			enemy.velocity = Vector2.ZERO
			state_timer -= delta
			visible = true
			queue_redraw()
			if state_timer <= 0.0:
				_execute_current_skill()
		STATE_CHARGE:
			_update_charge(delta)
		STATE_RECOVERY:
			enemy.velocity = Vector2.ZERO
			state_timer -= delta
			visible = impact_flash_time > 0.0
			queue_redraw()
			if state_timer <= 0.0:
				_finish_skill()
		_:
			_finish_skill()

func _start_skill(skill: Resource, direction: Vector2) -> void:
	current_skill = skill
	state = STATE_WINDUP
	state_timer = maxf(float(skill.windup), 0.01)
	cast_direction = direction.normalized()
	if cast_direction.length_squared() <= 0.001:
		cast_direction = _get_facing_direction()
	charge_has_hit = false
	cooldowns[skill.skill_id] = maxf(float(skill.cooldown), 0.1)
	visible = true
	impact_flash_time = 0.0
	if enemy != null:
		enemy.call("set_boss_skill_facing", cast_direction)
		enemy.call("start_boss_skill_visual", true, maxf(float(skill.windup) + float(skill.recovery), 0.24))
	queue_redraw()

func _execute_current_skill() -> void:
	if current_skill == null:
		_finish_skill()
		return
	var sfx_key: StringName = current_skill.sfx_key
	if sfx_key != &"":
		AudioManager.play_sfx_by_key(sfx_key)
	match current_skill.skill_type:
		TYPE_CHARGE:
			state = STATE_CHARGE
			state_timer = maxf(float(current_skill.charge_duration), 0.05)
			visible = false
			if enemy != null:
				enemy.call("start_boss_skill_visual", false, state_timer)
		TYPE_SLAM:
			_apply_target_damage(_get_skill_radius(current_skill), float(current_skill.damage_multiplier), 8.5)
			_begin_recovery(true)
		TYPE_RADIAL:
			_fire_radial(current_skill)
			_begin_recovery(true)
		TYPE_FAN:
			_fire_fan(current_skill)
			_begin_recovery(true)
		TYPE_SUMMON:
			_summon_helpers(current_skill)
			_begin_recovery(true)
		_:
			_begin_recovery(false)

func _begin_recovery(show_impact: bool) -> void:
	state = STATE_RECOVERY
	state_timer = maxf(float(current_skill.recovery), 0.08)
	if show_impact:
		impact_flash_time = minf(0.24, state_timer)
		visible = true
	queue_redraw()

func _finish_skill() -> void:
	current_skill = null
	state = STATE_IDLE
	state_timer = 0.0
	charge_has_hit = false
	if impact_flash_time <= 0.0:
		visible = false
	queue_redraw()

func _update_charge(delta: float) -> void:
	if current_skill == null or not is_instance_valid(enemy):
		cancel()
		return
	enemy.call("set_boss_skill_facing", cast_direction)
	enemy.velocity = cast_direction * float(current_skill.charge_speed)
	enemy.move_and_slide()
	if not charge_has_hit:
		charge_has_hit = _apply_target_damage(_get_skill_radius(current_skill), float(current_skill.damage_multiplier), 7.0)
	state_timer -= delta
	if state_timer <= 0.0:
		_begin_recovery(false)

func _apply_target_damage(radius: float, multiplier: float, shake_strength: float) -> bool:
	if not is_instance_valid(enemy) or not is_instance_valid(target):
		return false
	var padded_radius := radius + float(enemy.enemy_data.size)
	if enemy.global_position.distance_squared_to(target.global_position) > padded_radius * padded_radius:
		return false
	var health := target.get_node_or_null("HealthComponent")
	if health == null:
		return false
	health.take_damage(float(enemy.enemy_data.damage) * multiplier)
	var controller := get_tree().get_first_node_in_group("game_controller")
	if controller != null and controller.has_method("shake_camera"):
		controller.call("shake_camera", shake_strength)
	return true

func _fire_radial(skill: Resource) -> void:
	var projectile_pool := get_tree().get_first_node_in_group("enemy_projectile_pool")
	if projectile_pool == null:
		return
	var count: int = maxi(1, int(skill.projectile_count))
	if mobile_performance_mode:
		count = mini(count, 12)
	projectile_pool.call("fire_radial", enemy.global_position, count, float(enemy.enemy_data.damage) * float(skill.damage_multiplier), float(skill.projectile_speed), skill.projectile_texture)

func _fire_fan(skill: Resource) -> void:
	var projectile_pool := get_tree().get_first_node_in_group("enemy_projectile_pool")
	if projectile_pool == null:
		return
	var count: int = maxi(1, int(skill.projectile_count))
	if mobile_performance_mode:
		count = mini(count, 8)
	projectile_pool.call("fire_arc", enemy.global_position, cast_direction, count, float(skill.projectile_arc_degrees), float(enemy.enemy_data.damage) * float(skill.damage_multiplier), float(skill.projectile_speed), skill.projectile_texture)

func _summon_helpers(skill: Resource) -> void:
	if skill.summon_enemy_data == null or bool(skill.summon_enemy_data.boss):
		return
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	if spawner == null or not spawner.has_method("spawn_enemy_at"):
		return
	var count: int = maxi(0, int(skill.summon_count))
	if mobile_performance_mode:
		count = mini(count, MOBILE_SUMMON_LIMIT)
	var base_angle := randf() * TAU
	for index in count:
		var angle := base_angle + TAU * float(index) / float(maxi(1, count))
		var spawn_position := enemy.global_position + Vector2.from_angle(angle) * randf_range(180.0, 280.0)
		spawner.call("spawn_enemy_at", skill.summon_enemy_data, spawn_position)

func _find_usable_skill(distance: float, ignore_cooldown: bool = false, ignore_range: bool = false) -> Resource:
	var phase := _get_current_phase()
	for skill in _get_skill_list():
		if skill == null:
			continue
		if int(skill.min_phase) > phase:
			continue
		if not ignore_cooldown and float(cooldowns.get(skill.skill_id, 0.0)) > 0.0:
			continue
		if not ignore_range:
			if distance < float(skill.range_min):
				continue
			if float(skill.range_max) > 0.0 and distance > float(skill.range_max):
				continue
		return skill
	return null

func _find_forced_skill() -> Resource:
	var phase := _get_current_phase()
	var available: Array = []
	for skill in _get_skill_list():
		if skill != null and int(skill.min_phase) <= phase:
			available.append(skill)
	if available.is_empty():
		return null
	var skill: Resource = available[forced_skill_cursor % available.size()]
	forced_skill_cursor += 1
	return skill

func _update_cooldowns(delta: float) -> void:
	if cooldowns.is_empty():
		return
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)

func _update_impact_flash(delta: float) -> void:
	if impact_flash_time <= 0.0:
		return
	impact_flash_time = maxf(0.0, impact_flash_time - delta)
	if impact_flash_time <= 0.0 and state == STATE_IDLE:
		visible = false
	queue_redraw()

func _has_skills() -> bool:
	return is_instance_valid(enemy) and enemy.enemy_data != null and not enemy.enemy_data.boss_skills.is_empty()

func _get_skill_list() -> Array:
	if not is_instance_valid(enemy) or enemy.enemy_data == null:
		return []
	return enemy.enemy_data.boss_skills

func _get_current_phase() -> int:
	if not is_instance_valid(enemy) or enemy.enemy_data == null:
		return 1
	var health := enemy.get_node_or_null("HealthComponent")
	if health == null:
		return 1
	var layers: int = maxi(1, int(enemy.enemy_data.boss_health_bars))
	var per_layer: float = maxf(float(health.max_health) / float(layers), 1.0)
	var layers_left := clampi(int(ceil(maxf(float(health.current_health), 1.0) / per_layer)), 1, layers)
	return clampi(layers - layers_left + 1, 1, layers)

func _get_skill_radius(skill: Resource) -> float:
	return maxf(float(skill.telegraph_radius), 12.0)

func _get_facing_direction() -> Vector2:
	if is_instance_valid(enemy) and bool(enemy.get("facing_left")):
		return Vector2.LEFT
	return Vector2.RIGHT

func _draw() -> void:
	if current_skill == null:
		return
	if state == STATE_WINDUP:
		_draw_telegraph(current_skill)
	elif impact_flash_time > 0.0:
		_draw_impact(current_skill)

func _draw_telegraph(skill: Resource) -> void:
	match skill.skill_type:
		TYPE_CHARGE:
			_draw_charge_telegraph(skill)
		TYPE_FAN:
			_draw_fan_telegraph(skill)
		TYPE_RADIAL, TYPE_SLAM, TYPE_SUMMON:
			_draw_circle_telegraph(_get_skill_radius(skill))
		_:
			_draw_circle_telegraph(_get_skill_radius(skill))

func _draw_circle_telegraph(radius: float) -> void:
	draw_circle(Vector2.ZERO, radius, TELEGRAPH_FILL)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, TELEGRAPH_EDGE, 4.0)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 64, Color(1.0, 0.78, 0.32, 0.42), 2.0)

func _draw_fan_telegraph(skill: Resource) -> void:
	var radius := maxf(_get_skill_radius(skill), float(skill.projectile_speed) * 0.55)
	var arc := deg_to_rad(clampf(float(skill.projectile_arc_degrees), 5.0, 360.0))
	var center_angle := cast_direction.angle()
	var start_angle := center_angle - arc * 0.5
	var segments := 20
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for index in range(segments + 1):
		var t := float(index) / float(segments)
		points.append(Vector2.from_angle(start_angle + arc * t) * radius)
	draw_colored_polygon(points, TELEGRAPH_FILL)
	var outline := PackedVector2Array(points)
	outline.append(Vector2.ZERO)
	draw_polyline(outline, TELEGRAPH_EDGE, 3.0)

func _draw_charge_telegraph(skill: Resource) -> void:
	var length := maxf(float(skill.charge_speed) * float(skill.charge_duration), 120.0)
	var width := maxf(_get_skill_radius(skill), 28.0)
	var perpendicular := Vector2(-cast_direction.y, cast_direction.x) * width
	var end := cast_direction * length
	var points := PackedVector2Array([
		perpendicular,
		-perpendicular,
		end - perpendicular,
		end + perpendicular,
	])
	draw_colored_polygon(points, TELEGRAPH_FILL)
	draw_line(Vector2.ZERO, end, TELEGRAPH_EDGE, 5.0)
	draw_circle(end, width * 0.55, Color(1.0, 0.38, 0.12, 0.22))

func _draw_impact(skill: Resource) -> void:
	var radius := _get_skill_radius(skill)
	var alpha := clampf(impact_flash_time / maxf(float(skill.recovery), 0.08), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * (1.0 + (1.0 - alpha) * 0.28), Color(IMPACT_FILL.r, IMPACT_FILL.g, IMPACT_FILL.b, IMPACT_FILL.a * alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, Color(IMPACT_EDGE.r, IMPACT_EDGE.g, IMPACT_EDGE.b, IMPACT_EDGE.a * alpha), 5.0)
