extends CharacterBody2D

signal died

@export var move_speed: float = 200.0
@onready var health_component = $HealthComponent

var current_weapon = null

func _ready() -> void:
	GameManager.player = self
	health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * move_speed
	move_and_slide()

func _on_died() -> void:
	GameManager.player_died.emit()
	GameManager.end_game()
	died.emit()

func set_weapon(weapon):
	current_weapon = weapon
