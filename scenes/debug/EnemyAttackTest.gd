extends Node2D

const PlayerScene := preload("res://scenes/game/Player.tscn")
const EnemyScene := preload("res://scenes/game/Enemy.tscn")
const HealthComponentScript := preload("res://scripts/components/HealthComponent.gd")
const TEST_VISUAL_SCALE := 1.0

const ENEMY_DATA: Array[Resource] = [
	preload("res://resources/enemies/wolf.tres"),
	preload("res://resources/enemies/alpha_wolf.tres"),
	preload("res://resources/enemies/boar.tres"),
	preload("res://resources/enemies/forest_beast.tres"),
	preload("res://resources/enemies/thorn_porcupine.tres"),
	preload("res://resources/enemies/bandit.tres"),
	preload("res://resources/enemies/gunner.tres"),
	preload("res://resources/enemies/cult_wizard.tres"),
	preload("res://resources/enemies/elite.tres"),
	preload("res://resources/enemies/boss.tres"),
]

enum TestMode { ATTACK, RUN }

@onready var game_world: Node2D = $GameWorld
@onready var camera: Camera2D = $Camera2D
@onready var title_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/TitleLabel
@onready var detail_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/DetailLabel

var player: CharacterBody2D
var active_enemies: Array[CharacterBody2D] = []
var lane_nodes: Array[Node] = []
var run_anchors: Dictionary = {}
var camera_shake_strength: float = 0.0
var test_mode: int = TestMode.ATTACK
var mode_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	GameManager.start_run()
	_spawn_player()
	_build_mode_button()
	_apply_test_mode(TestMode.ATTACK)

func _process(delta: float) -> void:
	GameManager.update_game_time(delta)
	if test_mode == TestMode.RUN:
		for enemy in run_anchors:
			if is_instance_valid(enemy):
				enemy.global_position = run_anchors[enemy]
				enemy.active_time = 0.0
	if is_instance_valid(player):
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 24.0)
		camera.global_position = player.global_position + Vector2(
			randf_range(-camera_shake_strength, camera_shake_strength),
			randf_range(-camera_shake_strength, camera_shake_strength)
		)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _build_mode_button() -> void:
	mode_button = Button.new()
	mode_button.custom_minimum_size = Vector2(200, 44)
	mode_button.pressed.connect(_on_mode_button_pressed)
	var vbox: VBoxContainer = $CanvasLayer/Panel/MarginContainer/VBox
	vbox.add_child(mode_button)

func _on_mode_button_pressed() -> void:
	AudioManager.play_sfx_by_key(&"button_click")
	_apply_test_mode(TestMode.RUN if test_mode == TestMode.ATTACK else TestMode.ATTACK)

func _apply_test_mode(mode: int) -> void:
	test_mode = mode
	_clear_lanes()
	if mode == TestMode.ATTACK:
		_spawn_enemy_lanes()
		title_label.text = "Enemy Attack Animation Test"
		detail_label.text = "WASD / arrows move. Each enemy attacks one invincible dummy target."
		mode_button.text = "切换到跑步测试"
	else:
		_spawn_enemy_run_lanes()
		title_label.text = "Enemy Run Animation Test"
		detail_label.text = "WASD / arrows move. Each enemy chases the player and plays walk animation."
		mode_button.text = "切换到攻击测试"

func _clear_lanes() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	run_anchors.clear()
	for node in lane_nodes:
		if is_instance_valid(node):
			node.queue_free()
	lane_nodes.clear()

func _spawn_enemy_run_lanes() -> void:
	var columns := 5
	var spacing := Vector2(620, 390)
	var start := Vector2(-1240, -520)
	for index in ENEMY_DATA.size():
		var data := _create_test_enemy_data(ENEMY_DATA[index])
		var lane_position := start + Vector2(index % columns, index / columns) * spacing
		var run_target := Node2D.new()
		run_target.name = "%s_RunTarget" % data.enemy_id
		run_target.global_position = lane_position + Vector2(data.attack_range + 400.0, 0.0)
		game_world.add_child(run_target)
		lane_nodes.append(run_target)
		var enemy := EnemyScene.instantiate() as CharacterBody2D
		enemy.name = "%s_Runner" % data.enemy_id
		game_world.add_child(enemy)
		enemy.reset_for_spawn(data, run_target, lane_position)
		active_enemies.append(enemy)
		run_anchors[enemy] = lane_position
		_create_lane_label(data, lane_position + Vector2(-190, -115), true)

func _draw() -> void:
	draw_rect(Rect2(-1900, -1200, 3800, 2400), Color("28392f"))
	draw_rect(Rect2(-1900, -80, 3800, 160), Color("5f5944"))
	draw_rect(Rect2(-1500, -760, 3000, 2), Color(0.0, 0.0, 0.0, 0.25))
	draw_rect(Rect2(-1500, 760, 3000, 2), Color(0.0, 0.0, 0.0, 0.25))

func shake_camera(strength: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)

func get_nearest_enemy(origin: Vector2, max_range: float) -> Node2D:
	var nearest: Node2D
	var min_distance_sq := max_range * max_range
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.get("is_alive"):
			continue
		var distance_sq := origin.distance_squared_to(enemy.global_position)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			nearest = enemy
	return nearest

func _spawn_player() -> void:
	player = PlayerScene.instantiate() as CharacterBody2D
	player.name = "ControllablePlayer"
	player.global_position = Vector2(0, -130)
	game_world.add_child(player)
	player.set_world_bounds(Rect2(-1900, -1200, 3800, 2400))
	player.health_component.invincible = true
	player.ranged_weapon.firing_enabled = false
	player.orbit_flywheel.flywheel_count = 0
	player.drone_weapon.drone_unlocked = false

func _spawn_enemy_lanes() -> void:
	var columns := 5
	var spacing := Vector2(620, 390)
	var start := Vector2(-1240, -520)
	for index in ENEMY_DATA.size():
		var data := _create_test_enemy_data(ENEMY_DATA[index])
		var lane_position := start + Vector2(index % columns, index / columns) * spacing
		var dummy := _create_dummy_target(data, lane_position)
		lane_nodes.append(dummy)
		var attack_distance: float = maxf(data.attack_range * 0.6, 24.0)
		attack_distance = minf(attack_distance, data.attack_range - 6.0)
		var enemy_position := dummy.global_position - Vector2(attack_distance, 0.0)
		var enemy := EnemyScene.instantiate() as CharacterBody2D
		enemy.name = "%s_Attacker" % data.enemy_id
		game_world.add_child(enemy)
		enemy.reset_for_spawn(data, dummy, enemy_position)
		enemy.attack_timer = 0.0
		active_enemies.append(enemy)
		_create_lane_label(data, lane_position + Vector2(-190, -115), false)

func _create_test_enemy_data(source_data: Resource) -> Resource:
	var data := source_data.duplicate(true)
	data.visual_scale_multiplier *= TEST_VISUAL_SCALE
	data.size *= TEST_VISUAL_SCALE
	data.attack_range *= TEST_VISUAL_SCALE
	return data

func _create_dummy_target(data: Resource, lane_position: Vector2) -> StaticBody2D:
	var dummy := StaticBody2D.new()
	dummy.name = "%s_DummyPlayer" % data.enemy_id
	dummy.add_to_group("player")
	dummy.collision_layer = 1
	dummy.collision_mask = 0
	dummy.global_position = lane_position + Vector2(120, 0)

	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0 * TEST_VISUAL_SCALE
	collision.shape = circle
	dummy.add_child(collision)

	var health := HealthComponentScript.new()
	health.name = "HealthComponent"
	health.max_health = 100000.0
	health.invincible = true
	dummy.add_child(health)

	game_world.add_child(dummy)
	return dummy

func _create_lane_label(data: Resource, label_position: Vector2, run_mode: bool) -> void:
	var label := Label.new()
	label.global_position = label_position
	if run_mode:
		label.text = "%s\nspeed %.0f" % [data.enemy_id, data.move_speed]
	else:
		label.text = "%s\nrange %.0f  cd %.1f" % [data.enemy_id, data.attack_range, data.attack_cooldown]
	label.add_theme_color_override("font_color", Color("f4e7bd"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	game_world.add_child(label)
	lane_nodes.append(label)
