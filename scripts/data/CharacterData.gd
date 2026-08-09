class_name CharacterData
extends Resource

@export var character_id: StringName = &"sentinel"
@export var display_name: String = "村庄哨兵"
@export_multiline var description: String = ""
@export var body_texture: Texture2D
@export var rifle_texture: Texture2D
@export var model_scene: PackedScene
@export var weapon_model_scene: PackedScene
@export var model_scale: float = 1.0
@export var combat_profile: StringName = &"standard"
