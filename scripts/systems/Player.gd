extends CharacterBody2D

signal died

@export var move_speed: float = 210.0
@onready var health_component = $HealthComponent
@onready var sprite = $Sprite2D
@onready var ranged_weapon = $WeaponsNode/RangedWeapon

var is_alive: bool = true
var world_bounds := Rect2(-1760.0, -1060.0, 3520.0, 2120.0)
var flash_time: float = 0.0
var original_modulate := Color.WHITE

func _ready() -> void:
	GameManager.player = self
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	original_modulate = sprite.modulate

func _physics_process(_delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		return
	velocity = InputAdapter.get_move_vector() * move_speed
	move_and_slide()
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			sprite.modulate = original_modulate

func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds.grow(-28.0)

func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.stat_key:
		&"move_speed_multiplier":
			move_speed *= 1.0 + upgrade.amount
		&"max_health":
			health_component.increase_max_health(upgrade.amount, upgrade.amount)
		_:
			ranged_weapon.apply_upgrade(upgrade.stat_key, upgrade.amount)

func _on_health_changed(_current_health: float, _max_health: float) -> void:
	flash_time = 0.1
	sprite.modulate = Color(1.0, 0.25, 0.25)

func _on_died() -> void:
	if not is_alive:
		return
	is_alive = false
	GameManager.player_died.emit()
	GameManager.end_game(&"defeat")
	died.emit()
