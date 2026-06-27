class_name EnemyData
extends Resource

@export var enemy_id: StringName = &"enemy"
@export var display_name: String = "敌人"
@export var color: Color = Color(0.8, 0.3, 0.2)
@export var texture: Texture2D
@export var walk_texture: Texture2D
@export var attack_texture: Texture2D
@export var projectile_texture: Texture2D
@export var visual_scale_multiplier: float = 1.0
@export var size: float = 20.0
@export var max_health: float = 30.0
@export var move_speed: float = 100.0
@export var damage: float = 10.0
@export var exp_reward: int = 5
@export var min_spawn_time: float = 0.0
@export var max_spawn_time: float = 9999.0
@export var spawn_weight: float = 1.0
@export var spawn_region: StringName = &"any"
@export var ranged: bool = false
@export var attack_range: float = 42.0
@export var attack_cooldown: float = 1.0
@export var elite: bool = false
@export var boss: bool = false
