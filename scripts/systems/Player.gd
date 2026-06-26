extends CharacterBody2D

signal died

@export var move_speed: float = 210.0
@onready var health_component = $HealthComponent
@onready var body_sprite = $BodySprite
@onready var ranged_weapon = $WeaponsNode/RangedWeapon

const FRAME_SIZE := Vector2i(128, 128)
const ANIM_FRAME_COUNT := 4
const ANIM_FPS := 8.0
const DIRECTION_RIGHT := 1
const DIRECTION_LEFT := 3

var is_alive: bool = true
var world_bounds := Rect2(-1760.0, -1060.0, 3520.0, 2120.0)
var flash_time: float = 0.0
var original_modulate := Color.WHITE
var facing_row: int = DIRECTION_RIGHT
var animation_time: float = 0.0

func _ready() -> void:
	GameManager.player = self
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	original_modulate = body_sprite.modulate
	_update_sprite_frame(0)

func _physics_process(_delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		return
	var move_vector := InputAdapter.get_move_vector()
	velocity = move_vector * move_speed
	move_and_slide()
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)

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

func _on_health_changed(_current_health: float, _max_health: float) -> void:
	flash_time = 0.1
	body_sprite.modulate = Color(1.0, 0.25, 0.25)

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	GameManager.player_died.emit()
	GameManager.end_game(&"defeat")
	died.emit()

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
		Vector2(frame * FRAME_SIZE.x, DIRECTION_RIGHT * FRAME_SIZE.y),
		Vector2(FRAME_SIZE)
	)
