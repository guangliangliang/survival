extends Node2D

@export var character_data: CharacterData
@export var character_scene: PackedScene
@export var weapon_scene: PackedScene
@export_range(0.05, 10.0, 0.05) var model_scale: float = 1.0

@onready var visual: PlayerVisual3D = $PlayerVisual3D

var elapsed: float = 0.0
var current_phase: int = -1
var shoot_timer: float = 0.0

func _ready() -> void:
	if character_data != null:
		character_scene = character_data.model_scene
		weapon_scene = character_data.weapon_model_scene
		model_scale = character_data.model_scale
	visual.set_model_scale(model_scale)
	visual.set_character_scene(character_scene)
	visual.set_weapon_scene(weapon_scene)
	visual.set_aim_direction(Vector2.UP)

func _process(delta: float) -> void:
	elapsed += delta
	var phase := int(floor(elapsed / 2.0)) % 3
	if phase != current_phase:
		current_phase = phase
		match current_phase:
			0:
				visual.set_moving(false)
				visual.set_aim_direction(Vector2.UP)
			1:
				visual.set_moving(true)
			2:
				visual.set_moving(false)
				visual.set_aim_direction(Vector2.RIGHT)
				visual.play_shoot()
				shoot_timer = 0.6
	if current_phase == 1:
		visual.set_aim_direction(Vector2(cos(elapsed), sin(elapsed)))
	elif current_phase == 2:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = 0.6
			visual.play_shoot()
