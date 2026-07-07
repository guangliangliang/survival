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

const FRAME_SIZE := Vector2i(128, 128)
const ANIM_FRAME_COUNT := 4
const ANIM_FPS := 8.0
const DIRECTION_RIGHT := 1
const DIRECTION_LEFT := 3
const HEALTH_BAR_SIZE := Vector2(58.0, 7.0)
const HEALTH_BAR_OFFSET_Y := -104.0

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

func _ready() -> void:
	GameManager.player = self
	_apply_selected_character()
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	last_health = health_component.current_health
	original_modulate = body_sprite.modulate
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
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)
	InputAdapter.set_dash_cooldown_remaining(dash_cooldown_remaining)

func _process(delta: float) -> void:
	_update_walk_animation(delta)
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

func _on_health_changed(current_health: float, _max_health: float) -> void:
	if current_health < last_health and is_alive:
		AudioManager.play_sfx_by_key(&"player_hurt")
	last_health = current_health
	flash_time = 0.1
	body_sprite.modulate = Color(1.0, 0.25, 0.25)
	queue_redraw()

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	GameManager.player_died.emit()
	GameManager.end_game(&"defeat")
	queue_redraw()
	died.emit()

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

func _try_start_dash() -> void:
	if dash_cooldown_remaining > 0.0 or dash_time_remaining > 0.0:
		return
	var dash_direction := _get_dash_direction()
	dash_velocity = dash_direction * (dash_distance / maxf(dash_duration, 0.01))
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	InputAdapter.set_dash_cooldown_remaining(dash_cooldown_remaining)

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
