extends CharacterBody2D

signal died

@export var move_speed: float = 200.0
@onready var health_component = $HealthComponent
@onready var sprite = $Sprite2D

var current_weapon = null
var is_flashing = false
var flash_timer = 0.0
var flash_duration = 0.1
var original_modulate = Color(1, 1, 1, 1)

func _ready() -> void:
	GameManager.player = self
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	original_modulate = sprite.modulate

func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * move_speed
	move_and_slide()

func _process(delta: float):
	if is_flashing:
		flash_timer += delta
		if flash_timer >= flash_duration:
			is_flashing = false
			sprite.modulate = original_modulate

func _on_health_changed(current_health: float, max_health: float):
	if current_health < max_health:
		_flash()

func _flash():
	is_flashing = true
	flash_timer = 0.0
	sprite.modulate = Color(1, 0, 0, 1)

func _on_died() -> void:
	GameManager.player_died.emit()
	GameManager.end_game()
	died.emit()

func set_weapon(weapon):
	current_weapon = weapon
