extends Node2D

const EnemyScene := preload("res://scenes/game/Enemy.tscn")
const EnemyProjectilePoolScript := preload("res://scripts/managers/EnemyProjectilePool.gd")
const EnemyBulletScene := preload("res://scenes/game/EnemyBullet.tscn")

const BOSS_DATA: Array[Resource] = [
	preload("res://resources/enemies/alpha_wolf.tres"),
	preload("res://resources/enemies/forest_beast.tres"),
	preload("res://resources/enemies/boss.tres"),
]

@onready var game_world: Node2D = $GameWorld
@onready var camera: Camera2D = $Camera2D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var ui_panel: PanelContainer = $CanvasLayer/Panel
@onready var ui_vbox: VBoxContainer = $CanvasLayer/Panel/MarginContainer/VBox
@onready var title_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/TitleLabel
@onready var info_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/InfoLabel
@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/StatusLabel
@onready var attack_button: Button = $CanvasLayer/AttackButton

var current_boss: CharacterBody2D
var current_boss_index: int = 0
var camera_shake_strength: float = 0.0
var boss_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	GameManager.start_run()
	_setup_ui()
	_spawn_boss(0)
	title_label.text = "Boss 测试场景"
	_update_info_label()
	
	attack_button.pressed.connect(_on_attack_button_pressed)
	_style_attack_button()

func _process(delta: float) -> void:
	GameManager.update_game_time(delta)
	_handle_input(delta)
	_update_camera(delta)
	_update_status_label()

func _draw() -> void:
	draw_rect(Rect2(-1900, -1200, 3800, 2400), Color("28392f"))
	draw_rect(Rect2(-1900, -80, 3800, 160), Color("5f5944"))

func _setup_ui() -> void:
	var button_hbox: HBoxContainer = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 10)
	ui_vbox.add_child(button_hbox)
	
	for i in range(BOSS_DATA.size()):
		var data: Resource = BOSS_DATA[i]
		var btn: Button = Button.new()
		btn.text = (data as Resource).display_name
		btn.custom_minimum_size = Vector2(140, 50)
		btn.pressed.connect(_on_boss_button_pressed.bind(i))
		button_hbox.add_child(btn)
		boss_buttons.append(btn)
	
	_update_button_styles()

func _update_button_styles() -> void:
	for i in range(boss_buttons.size()):
		var btn: Button = boss_buttons[i]
		var data: Resource = BOSS_DATA[i]
		if i == current_boss_index:
			btn.add_theme_stylebox_override("normal", _button_box(Color("5a3a22"), Color("d9b56b")))
		else:
			btn.add_theme_stylebox_override("normal", _button_box(Color("3b332d"), Color("8e8069")))
		btn.add_theme_color_override("font_color", Color("f4e2b2"))
		btn.add_theme_font_size_override("font_size", 16)

func _on_boss_button_pressed(index: int) -> void:
	current_boss_index = index
	_spawn_boss(index)
	_update_button_styles()
	AudioManager.play_sfx_by_key(&"button_click")

func _spawn_boss(index: int) -> void:
	if is_instance_valid(current_boss):
		current_boss.queue_free()
	
	var data: Resource = BOSS_DATA[index].duplicate(true)
	data.visual_scale_multiplier = (data as Resource).visual_scale_multiplier * 2.0
	data.size = (data as Resource).size * 2.0
	current_boss = EnemyScene.instantiate() as CharacterBody2D
	current_boss.name = "%s_TestBoss" % (data as Resource).enemy_id
	game_world.add_child(current_boss)
	current_boss.reset_for_spawn(data, null, Vector2(0, 0))
	
	title_label.text = "Boss 测试 - %s" % (data as Resource).display_name

func _handle_input(delta: float) -> void:
	if not is_instance_valid(current_boss):
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
		return
	
	if Input.is_action_just_pressed("attack"):
		_force_boss_attack()
	
	if Input.is_action_just_pressed("move_up") and Input.is_action_pressed("move_down"):
		_spawn_boss(current_boss_index)
		AudioManager.play_sfx_by_key(&"button_click")
	
	_move_boss(delta)

func _move_boss(delta: float) -> void:
	var move_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("move_up"):
		move_dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		move_dir.y += 1.0
	
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		var data: Resource = current_boss.get("enemy_data") as Resource
		if data:
			current_boss.velocity = move_dir * data.move_speed
			current_boss.move_and_slide()
			
			if move_dir.x > 0.1:
				current_boss.set("facing_left", false)
			elif move_dir.x < -0.1:
				current_boss.set("facing_left", true)
	else:
		current_boss.velocity = Vector2.ZERO

func _force_boss_attack() -> void:
	if not is_instance_valid(current_boss):
		return
	
	if current_boss.has_method("trigger_attack"):
		current_boss.trigger_attack()

func _update_camera(delta: float) -> void:
	if is_instance_valid(current_boss):
		var target_pos: Vector2 = current_boss.global_position
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 24.0)
		camera.global_position = target_pos + Vector2(
			randf_range(-camera_shake_strength, camera_shake_strength),
			randf_range(-camera_shake_strength, camera_shake_strength)
		)

func _update_info_label() -> void:
	info_label.text = "WASD 移动 Boss | 空格 攻击 | 同时按 W+S 重置 Boss | ESC 返回菜单"

func _update_status_label() -> void:
	if not is_instance_valid(current_boss):
		status_label.text = "Boss: 无"
		return
	
	var data: Resource = current_boss.get("enemy_data") as Resource
	var health_comp: Node = current_boss.get_node_or_null("HealthComponent")
	if not data or not health_comp:
		return
	
	var hp: float = health_comp.get("current_health") as float
	var max_hp: float = health_comp.get("max_health") as float
	var phase_text: String = "一阶段"
	if hp <= max_hp * 0.5:
		phase_text = "二阶段 (攻击加速!)"
	
	var attack_count: int = current_boss.get("attack_count") as int
	status_label.text = "生命值: %.0f / %.0f | %s | 攻击次数: %d" % [
		hp, max_hp, phase_text, attack_count
	]

func shake_camera(strength: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)

func _on_attack_button_pressed() -> void:
	_force_boss_attack()

func _style_attack_button() -> void:
	attack_button.add_theme_stylebox_override("normal", _button_box(Color(0.7, 0.2, 0.15), Color(1.0, 0.6, 0.3)))
	attack_button.add_theme_stylebox_override("hover", _button_box(Color(0.8, 0.25, 0.2), Color(1.0, 0.75, 0.4)))
	attack_button.add_theme_stylebox_override("pressed", _button_box(Color(0.5, 0.15, 0.1), Color(0.8, 0.5, 0.25)))
	attack_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	attack_button.add_theme_font_size_override("font_size", 24)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(16)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 4)
	return box
