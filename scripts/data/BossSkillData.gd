class_name BossSkillData
extends Resource

@export var skill_id: StringName = &"boss_skill"
@export var display_name: String = "Boss Skill"
@export var skill_type: StringName = &"slam"
@export var min_phase: int = 1
@export var cooldown: float = 6.0
@export var windup: float = 0.5
@export var recovery: float = 0.35
@export var range_min: float = 0.0
@export var range_max: float = 240.0
@export var damage_multiplier: float = 1.0
@export var telegraph_radius: float = 120.0
@export var projectile_count: int = 0
@export var projectile_arc_degrees: float = 360.0
@export var projectile_speed: float = 300.0
@export var charge_speed: float = 560.0
@export var charge_duration: float = 0.35
@export var summon_enemy_data: Resource
@export var summon_count: int = 0
@export var sfx_key: StringName = &""
@export var projectile_texture: Texture2D
