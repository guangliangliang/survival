class_name PlayerVisual3D
extends Node2D

const WEAPON_SOCKET_NAME := "WeaponSocket3D"
const MUZZLE_SOCKET_NAME := "MuzzleSocket3D"

@export var viewport_size := Vector2i(256, 256)
@export var sprite_scale: float = 1.0
@export_range(0.05, 10.0, 0.05) var model_scale: float = 1.0
@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var shoot_animation: StringName = &"shoot"

@onready var viewport: SubViewport = $SubViewport
@onready var viewport_sprite: Sprite2D = $ViewportSprite
@onready var character_root: Node3D = $SubViewport/WorldRoot/CharacterRoot
@onready var fallback_weapon_socket: Node3D = $SubViewport/WorldRoot/CharacterRoot/WeaponSocket3D
@onready var camera: Camera3D = $SubViewport/WorldRoot/Camera3D
@onready var key_light: DirectionalLight3D = $SubViewport/WorldRoot/DirectionalLight3D

var character_scene: PackedScene
var weapon_scene: PackedScene
var character_instance: Node3D
var weapon_instance: Node3D
var animation_player: AnimationPlayer
var moving: bool = false
var shooting: bool = false

func _ready() -> void:
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_sprite.texture = viewport.get_texture()
	viewport_sprite.scale = Vector2.ONE * sprite_scale
	_configure_camera()
	_play_locomotion_animation()

func set_character_scene(scene: PackedScene) -> void:
	character_scene = scene
	_clear_weapon()
	_clear_character()
	if character_scene == null:
		_instantiate_weapon()
		return
	var instance := character_scene.instantiate()
	if not (instance is Node3D):
		push_warning("PlayerVisual3D character_scene root must be Node3D.")
		instance.queue_free()
		_instantiate_weapon()
		return
	character_instance = instance as Node3D
	character_root.add_child(character_instance)
	character_instance.scale = Vector3.ONE * model_scale
	animation_player = _find_animation_player(character_instance)
	_connect_animation_player()
	_instantiate_weapon()
	_play_locomotion_animation()

func set_weapon_scene(scene: PackedScene) -> void:
	weapon_scene = scene
	_instantiate_weapon()

func set_model_scale(value: float) -> void:
	model_scale = maxf(0.05, value)
	if character_instance != null:
		character_instance.scale = Vector3.ONE * model_scale

func set_moving(is_moving: bool) -> void:
	if moving == is_moving:
		return
	moving = is_moving
	if not shooting:
		_play_locomotion_animation()

func play_shoot() -> void:
	if animation_player == null or not animation_player.has_animation(shoot_animation):
		return
	shooting = true
	_play_animation(shoot_animation)

func set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	var forward := Vector3(direction.x, 0.0, direction.y).normalized()
	character_root.rotation.y = atan2(-forward.x, -forward.z)

func get_muzzle_socket() -> Node3D:
	if weapon_instance == null:
		return null
	return _find_node3d_by_name(weapon_instance, MUZZLE_SOCKET_NAME)

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	camera.position = Vector3(3.0, 3.2, 4.2)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	key_light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	key_light.light_energy = 1.6

func _instantiate_weapon() -> void:
	_clear_weapon()
	if weapon_scene == null:
		return
	var instance := weapon_scene.instantiate()
	if not (instance is Node3D):
		push_warning("PlayerVisual3D weapon_scene root must be Node3D.")
		instance.queue_free()
		return
	weapon_instance = instance as Node3D
	_get_weapon_socket().add_child(weapon_instance)
	weapon_instance.transform = Transform3D.IDENTITY

func _clear_character() -> void:
	animation_player = null
	character_instance = _free_instance(character_instance)

func _clear_weapon() -> void:
	weapon_instance = _free_instance(weapon_instance)

func _free_instance(instance: Node3D) -> Node3D:
	if instance != null and is_instance_valid(instance):
		instance.queue_free()
	return null

func _get_weapon_socket() -> Node3D:
	if character_instance != null:
		var socket := _find_node3d_by_name(character_instance, WEAPON_SOCKET_NAME)
		if socket != null:
			return socket
	return fallback_weapon_socket

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.find_children("*", "AnimationPlayer", true, false):
		return child as AnimationPlayer
	return null

func _find_node3d_by_name(root: Node, target_name: String) -> Node3D:
	if root.name == target_name and root is Node3D:
		return root as Node3D
	var found := root.find_child(target_name, true, false)
	if found is Node3D:
		return found as Node3D
	return null

func _connect_animation_player() -> void:
	if animation_player == null:
		return
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func _play_locomotion_animation() -> void:
	if animation_player == null:
		return
	_play_animation(run_animation if moving else idle_animation)

func _play_animation(animation_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		return
	if animation_player.current_animation == animation_name and animation_player.is_playing():
		return
	animation_player.play(animation_name)

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != shoot_animation:
		return
	shooting = false
	_play_locomotion_animation()
