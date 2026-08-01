extends CharacterBody2D

signal died

@export var move_speed: float = 210.0
@export var dash_distance: float = 220.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 10.0
@onready var health_component = $HealthComponent
@onready var body_sprite = $BodySprite
@onready var ranged_weapon = $WeaponsNode/RangedWeapon
@onready var orbit_flywheel = $WeaponsNode/OrbitFlywheel
@onready var drone_weapon = $WeaponsNode/DroneWeapon
@onready var blossom_scatter = $WeaponsNode/BlossomScatter
@onready var sword_rain = $WeaponsNode/SwordRainStorm
@onready var heal = $WeaponsNode/HealSkill

const FRAME_SIZE := Vector2i(128, 128)
const ANIM_FRAME_COUNT := 4
const ANIM_FPS := 8.0
const DIRECTION_RIGHT := 1
const DIRECTION_LEFT := 3
const HEALTH_BAR_SIZE := Vector2(58.0, 7.0)
const HEALTH_BAR_OFFSET_Y := -104.0
const AMMO_BAR_OFFSET_Y := -116.0
const AMMO_BAR_WIDTH := 46.0
const AMMO_BAR_HEIGHT := 5.0
const AMMO_DOT_SIZE := 4.0
const AMMO_DOT_SPACING := 6.0
const AMMO_MAX_SPAN := 58.0
const AMMO_SEGMENT_THRESHOLD := 14
const MOBILE_STATUS_REDRAW_INTERVAL := 0.1
const FREE_REVIVE_HEALTH_RATIO := 0.5
const FREE_REVIVE_INVINCIBLE_DURATION := 2.0

var is_alive: bool = true
var world_bounds := Rect2(-1760.0, -1060.0, 3520.0, 2120.0)
var flash_time: float = 0.0
var original_modulate := Color.WHITE
var facing_row: int = DIRECTION_RIGHT
var animation_time: float = 0.0
var last_health: float = 0.0
var dash_cooldown_remaining: float = 0.0
var dash_time_remaining: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO
var mobile_performance_mode: bool = false
var status_redraw_timer: float = 0.0
var revive_invincible_time: float = 0.0
var revive_invincible_active: bool = false
var revive_previous_invincible: bool = false

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	GameManager.player = self
	_apply_selected_character()
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	last_health = health_component.current_health
	original_modulate = body_sprite.modulate
	InputAdapter.set_dash_cooldown(dash_cooldown_remaining, dash_cooldown)
	_update_sprite_frame(0)
	queue_redraw()

func _apply_selected_character() -> void:
	var character_data: Resource = GameManager.selected_character
	if character_data == null:
		return
	if character_data.body_texture != null:
		body_sprite.texture = character_data.body_texture
	if character_data.rifle_texture != null:
		ranged_weapon.set_arms_texture(character_data.rifle_texture)

func _physics_process(delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		return
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	if InputAdapter.consume_dash_requested():
		_try_start_dash()
	if dash_time_remaining > 0.0:
		dash_time_remaining = maxf(0.0, dash_time_remaining - delta)
		velocity = dash_velocity
	else:
		var move_vector := InputAdapter.get_move_vector()
		velocity = move_vector * move_speed
	move_and_slide()
	_update_status_redraw(delta)
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)
	InputAdapter.set_dash_cooldown(dash_cooldown_remaining, dash_cooldown)

func _process(delta: float) -> void:
	_update_walk_animation(delta)
	_update_revive_invincibility(delta)
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			body_sprite.modulate = original_modulate

func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds.grow(-28.0)

func apply_upgrade(upgrade: Resource) -> void:
	match upgrade.stat_key:
		&"move_speed_multiplier":
			move_speed *= 1.0 + upgrade.amount
		&"max_health":
			health_component.increase_max_health(upgrade.amount, upgrade.amount)
		_:
			ranged_weapon.apply_upgrade(upgrade.stat_key, upgrade.amount)
			orbit_flywheel.apply_upgrade(upgrade.stat_key, upgrade.amount)
			drone_weapon.apply_upgrade(upgrade.stat_key, upgrade.amount)
			blossom_scatter.apply_upgrade(upgrade.stat_key, upgrade.amount)
			sword_rain.apply_upgrade(upgrade.stat_key, upgrade.amount)
			heal.apply_upgrade(upgrade.stat_key, upgrade.amount)

func get_health_component() -> Node:
	return health_component

func revive(health_ratio: float = FREE_REVIVE_HEALTH_RATIO, invincibility_duration: float = FREE_REVIVE_INVINCIBLE_DURATION) -> void:
	is_alive = true
	velocity = Vector2.ZERO
	dash_time_remaining = 0.0
	dash_velocity = Vector2.ZERO
	health_component.revive(health_ratio)
	last_health = health_component.current_health
	flash_time = 0.0
	_start_revive_invincibility(invincibility_duration)
	AudioManager.play_sfx_by_key(&"heal_cast", -2.0)
	queue_redraw()

func _update_status_redraw(delta: float) -> void:
	if not mobile_performance_mode:
		queue_redraw()
		return
	status_redraw_timer -= delta
	if status_redraw_timer > 0.0:
		return
	status_redraw_timer = MOBILE_STATUS_REDRAW_INTERVAL
	queue_redraw()

func _on_health_changed(current_health: float, _max_health: float) -> void:
	var damaged := current_health < last_health
	if damaged and is_alive:
		AudioManager.play_sfx_by_key(&"player_hurt")
		flash_time = 0.1
		body_sprite.modulate = Color(1.0, 0.25, 0.25)
	last_health = current_health
	queue_redraw()

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	GameManager.player_died.emit()
	if GameManager.free_revives_remaining <= 0:
		GameManager.end_game(&"defeat")
	queue_redraw()
	died.emit()

func _start_revive_invincibility(duration: float) -> void:
	if duration <= 0.0:
		body_sprite.modulate = original_modulate
		return
	if not revive_invincible_active:
		revive_previous_invincible = health_component.invincible
	revive_invincible_active = true
	revive_invincible_time = duration
	health_component.invincible = true
	body_sprite.modulate = Color(1.0, 0.94, 0.48)

func _update_revive_invincibility(delta: float) -> void:
	if not revive_invincible_active:
		return
	revive_invincible_time = maxf(0.0, revive_invincible_time - delta)
	var pulse := 0.72 + 0.28 * absf(sin(revive_invincible_time * 14.0))
	body_sprite.modulate = Color(1.0, 0.94, 0.48, pulse)
	if revive_invincible_time > 0.0:
		return
	revive_invincible_active = false
	health_component.invincible = revive_previous_invincible
	body_sprite.modulate = original_modulate

func _draw() -> void:
	if not is_alive or health_component.max_health <= 0.0:
		return
	var ratio := clampf(health_component.current_health / health_component.max_health, 0.0, 1.0)
	var top_left := Vector2(-HEALTH_BAR_SIZE.x * 0.5, HEALTH_BAR_OFFSET_Y)
	var background_rect := Rect2(top_left, HEALTH_BAR_SIZE)
	var fill_rect := Rect2(top_left, Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y))
	draw_rect(background_rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.62))
	draw_rect(background_rect, Color(0.14, 0.04, 0.035, 0.88))
	draw_rect(fill_rect, Color(0.86, 0.08, 0.06, 0.96))
	draw_rect(background_rect, Color(0.02, 0.015, 0.01, 0.95), false, 1.0)
	_draw_ammo()

func _draw_ammo() -> void:
	var info: Dictionary = ranged_weapon.get_ammo_info()
	var max_ammo: int = int(info.get("max", 0))
	if max_ammo <= 0:
		return
	if info.get("reloading", false):
		var progress := clampf(float(info.get("reload_progress", 0.0)), 0.0, 1.0)
		var bar_left := Vector2(-AMMO_BAR_WIDTH * 0.5, AMMO_BAR_OFFSET_Y)
		var bg := Rect2(bar_left, Vector2(AMMO_BAR_WIDTH, AMMO_BAR_HEIGHT))
		var fill := Rect2(bar_left, Vector2(AMMO_BAR_WIDTH * progress, AMMO_BAR_HEIGHT))
		draw_rect(bg.grow(1.5), Color(0.0, 0.0, 0.0, 0.6))
		draw_rect(bg, Color(0.1, 0.1, 0.12, 0.85))
		draw_rect(fill, Color(0.98, 0.78, 0.22, 0.96))
		return
	var current: int = int(info.get("current", 0))
	if max_ammo > AMMO_SEGMENT_THRESHOLD:
		var spacing := AMMO_MAX_SPAN / float(max_ammo)
		var bar_left := -AMMO_MAX_SPAN * 0.5
		for index in max_ammo:
			var x := bar_left + float(index) * spacing
			var seg := Rect2(Vector2(x, AMMO_BAR_OFFSET_Y), Vector2(maxf(spacing - 1.0, 1.0), AMMO_BAR_HEIGHT))
			if index < current:
				draw_rect(seg, Color(0.98, 0.82, 0.3, 0.96))
			else:
				draw_rect(seg, Color(0.2, 0.18, 0.14, 0.7))
		return
	var spacing := minf(AMMO_DOT_SPACING, AMMO_MAX_SPAN / float(maxi(1, max_ammo - 1)))
	var total_width := float(max_ammo - 1) * spacing
	var start_x := -total_width * 0.5
	for index in max_ammo:
		var center := Vector2(start_x + float(index) * spacing, AMMO_BAR_OFFSET_Y)
		var dot := Rect2(center - Vector2(AMMO_DOT_SIZE * 0.5, AMMO_DOT_SIZE * 0.5), Vector2(AMMO_DOT_SIZE, AMMO_DOT_SIZE))
		if index < current:
			draw_rect(dot, Color(0.98, 0.82, 0.3, 0.96))
		else:
			draw_rect(dot, Color(0.2, 0.18, 0.14, 0.7))

func _try_start_dash() -> void:
	if dash_cooldown_remaining > 0.0 or dash_time_remaining > 0.0:
		return
	var dash_direction := _get_dash_direction()
	dash_velocity = dash_direction * (dash_distance / maxf(dash_duration, 0.01))
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	InputAdapter.set_dash_cooldown(dash_cooldown_remaining, dash_cooldown)
	AudioManager.play_sfx_by_key(&"dash_cast", -3.0)

func _get_dash_direction() -> Vector2:
	var move_vector := InputAdapter.get_move_vector()
	if move_vector.length_squared() > 0.01:
		return move_vector.normalized()
	return Vector2.LEFT if facing_row == DIRECTION_LEFT else Vector2.RIGHT

func _update_walk_animation(delta: float) -> void:
	var move_vector := InputAdapter.get_move_vector()
	ranged_weapon.refresh_aim_direction()
	var facing_vector := move_vector
	if absf(move_vector.x) <= 0.05 and ranged_weapon.has_aim_target():
		facing_vector = ranged_weapon.get_aim_direction()
	var frame := 0
	if move_vector.length_squared() <= 0.01:
		animation_time = 0.0
	else:
		animation_time += delta
		frame = int(animation_time * ANIM_FPS) % ANIM_FRAME_COUNT
	facing_row = _get_direction_row(facing_vector)
	_update_sprite_frame(frame)
	ranged_weapon.set_body_pose(facing_row, frame)

func _get_direction_row(direction: Vector2) -> int:
	if direction.x > 0.05:
		return DIRECTION_RIGHT
	if direction.x < -0.05:
		return DIRECTION_LEFT
	return facing_row

func _update_sprite_frame(frame: int) -> void:
	body_sprite.flip_h = facing_row == DIRECTION_LEFT
	body_sprite.region_rect = Rect2(
		Vector2(frame * FRAME_SIZE.x, 0),
		Vector2(FRAME_SIZE)
	)
