extends Node2D

const EnemyScene := preload("res://scenes/game/Enemy.tscn")
const PlayerScene := preload("res://scenes/game/Player.tscn")

const BOSS_DATA: Array[Resource] = [
	preload("res://resources/enemies/alpha_wolf.tres"),
	preload("res://resources/enemies/forest_beast.tres"),
	preload("res://resources/enemies/boss.tres"),
]

@onready var game_world: Node2D = $GameWorld
@onready var camera: Camera2D = $Camera2D
@onready var ui_vbox: VBoxContainer = $CanvasLayer/Panel/MarginContainer/VBox
@onready var title_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/TitleLabel
@onready var info_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/InfoLabel
@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBox/StatusLabel
@onready var attack_button: Button = $CanvasLayer/AttackButton

var current_boss: CharacterBody2D
var player_dummy: CharacterBody2D
var current_boss_index: int = 0
var camera_shake_strength: float = 0.0
var boss_buttons: Array[Button] = []
var phase_buttons: Array[Button] = []
var skill_button: Button
var summoned_enemies: Array[CharacterBody2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	GameManager.start_run()
	_setup_ui()
	_create_player_dummy()
	_spawn_boss(0)
	title_label.text = "Boss 测试"
	_update_info_label()
	attack_button.text = "普通攻击（空格）"
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
	if is_instance_valid(player_dummy):
		draw_circle(player_dummy.global_position, 34.0, Color(0.2, 0.8, 1.0, 0.2))
		draw_arc(player_dummy.global_position, 34.0, 0.0, TAU, 48, Color(0.55, 0.92, 1.0, 0.85), 3.0)

func _setup_ui() -> void:
	var button_hbox := HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 10)
	ui_vbox.add_child(button_hbox)

	for i in range(BOSS_DATA.size()):
		var data: Resource = BOSS_DATA[i]
		var btn := Button.new()
		btn.text = data.display_name
		btn.custom_minimum_size = Vector2(140, 50)
		btn.pressed.connect(_on_boss_button_pressed.bind(i))
		button_hbox.add_child(btn)
		boss_buttons.append(btn)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	ui_vbox.add_child(action_hbox)

	skill_button = Button.new()
	skill_button.text = "强制释放技能"
	skill_button.custom_minimum_size = Vector2(150, 46)
	skill_button.pressed.connect(_on_skill_button_pressed)
	action_hbox.add_child(skill_button)

	for phase in range(1, 4):
		var phase_btn := Button.new()
		phase_btn.text = "阶段 %d" % phase
		phase_btn.custom_minimum_size = Vector2(96, 46)
		phase_btn.pressed.connect(_on_phase_button_pressed.bind(phase))
		action_hbox.add_child(phase_btn)
		phase_buttons.append(phase_btn)

	_update_button_styles()

func _update_button_styles() -> void:
	for i in range(boss_buttons.size()):
		var btn := boss_buttons[i]
		if i == current_boss_index:
			btn.add_theme_stylebox_override("normal", _button_box(Color("5a3a22"), Color("d9b56b")))
		else:
			btn.add_theme_stylebox_override("normal", _button_box(Color("3b332d"), Color("8e8069")))
		btn.add_theme_color_override("font_color", Color("f4e2b2"))
		btn.add_theme_font_size_override("font_size", 16)
	for btn in phase_buttons:
		btn.add_theme_stylebox_override("normal", _button_box(Color("3b332d"), Color("8e8069")))
		btn.add_theme_color_override("font_color", Color("f4e2b2"))
		btn.add_theme_font_size_override("font_size", 15)
	if skill_button != null:
		skill_button.add_theme_stylebox_override("normal", _button_box(Color("5a3a22"), Color("d9b56b")))
		skill_button.add_theme_color_override("font_color", Color("f4e2b2"))
		skill_button.add_theme_font_size_override("font_size", 16)

func _on_boss_button_pressed(index: int) -> void:
	current_boss_index = index
	_spawn_boss(index)
	_update_button_styles()
	AudioManager.play_sfx_by_key(&"button_click")

func _spawn_boss(index: int) -> void:
	if is_instance_valid(current_boss):
		current_boss.queue_free()
	_clear_summons()

	var data: Resource = BOSS_DATA[index].duplicate(true)
	current_boss = EnemyScene.instantiate() as CharacterBody2D
	current_boss.name = "%s_TestBoss" % data.enemy_id
	game_world.add_child(current_boss)
	current_boss.reset_for_spawn(data, player_dummy, Vector2.ZERO)
	title_label.text = "Boss 测试 - %s" % data.display_name

func _handle_input(delta: float) -> void:
	if not is_instance_valid(current_boss):
		return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
		return
	if Input.is_action_just_pressed("attack"):
		_force_boss_attack()
	if Input.is_action_just_pressed("reset_boss"):
		_spawn_boss(current_boss_index)
		AudioManager.play_sfx_by_key(&"button_click")
	_move_boss(delta)

func _move_boss(delta: float) -> void:
	var move_dir := Vector2.ZERO
	if Input.is_action_pressed("boss_move_left"):
		move_dir.x -= 1.0
	if Input.is_action_pressed("boss_move_right"):
		move_dir.x += 1.0
	if Input.is_action_pressed("boss_move_up"):
		move_dir.y -= 1.0
	if Input.is_action_pressed("boss_move_down"):
		move_dir.y += 1.0
	if move_dir.length_squared() <= 0.0:
		return
	move_dir = move_dir.normalized()
	var data: Resource = current_boss.get("enemy_data") as Resource
	if data == null:
		return
	current_boss.velocity = move_dir * data.move_speed
	current_boss.move_and_slide()
	if move_dir.x > 0.1:
		current_boss.set("facing_left", false)
	elif move_dir.x < -0.1:
		current_boss.set("facing_left", true)

func _force_boss_attack() -> void:
	if is_instance_valid(current_boss) and current_boss.has_method("trigger_attack"):
		current_boss.trigger_attack()

func _force_boss_skill() -> void:
	if is_instance_valid(current_boss) and current_boss.has_method("trigger_boss_skill"):
		current_boss.call("trigger_boss_skill")

func _update_camera(delta: float) -> void:
	if not is_instance_valid(current_boss):
		return
	var target_pos: Vector2 = current_boss.global_position
	camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 24.0)
	camera.global_position = target_pos + Vector2(
		randf_range(-camera_shake_strength, camera_shake_strength),
		randf_range(-camera_shake_strength, camera_shake_strength)
	)

func _update_info_label() -> void:
	info_label.text = "WASD 移动主角 | IJKL 移动 Boss | 空格普通攻击 | 强制释放技能会施放已解锁技能 | 阶段按钮设置血量 | R 重置 | ESC 返回菜单"

func _update_status_label() -> void:
	if not is_instance_valid(current_boss):
		status_label.text = "Boss：无"
		return
	var data: Resource = current_boss.get("enemy_data") as Resource
	var health_comp: Node = current_boss.get_node_or_null("HealthComponent")
	if data == null or health_comp == null:
		return
	var hp: float = health_comp.get("current_health")
	var max_hp: float = health_comp.get("max_health")
	var layers: int = max(int(data.boss_health_bars), 1)
	var per_layer := max_hp / float(layers)
	var layers_left := clampi(int(ceil(maxf(hp, 1.0) / per_layer)), 1, layers)
	var phase := layers - layers_left + 1
	var attack_count: int = current_boss.get("attack_count")
	var skill_text := "技能：无"
	if current_boss.has_method("get_boss_skill_debug_text"):
		skill_text = current_boss.call("get_boss_skill_debug_text")
	status_label.text = "生命值 %.0f / %.0f | 阶段 %d | 攻击次数 %d\n%s\n召唤物 %d | 目标 x %.0f" % [
		hp, max_hp, phase, attack_count, skill_text, _get_live_summon_count(), player_dummy.global_position.x
	]

func shake_camera(strength: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)

func _on_attack_button_pressed() -> void:
	_force_boss_attack()

func _on_skill_button_pressed() -> void:
	_force_boss_skill()

func _on_phase_button_pressed(phase: int) -> void:
	_set_boss_phase(phase)

func _create_player_dummy() -> void:
	player_dummy = PlayerScene.instantiate() as CharacterBody2D
	player_dummy.name = "BossTestPlayer"
	player_dummy.process_mode = Node.PROCESS_MODE_ALWAYS
	game_world.add_child(player_dummy)
	player_dummy.global_position = Vector2(440, 0)

	var ranged := player_dummy.get_node_or_null("WeaponsNode/RangedWeapon")
	if ranged != null:
		ranged.firing_enabled = false

	var health := player_dummy.get_node_or_null("HealthComponent") as Node
	if health != null:
		health.max_health = 1000000.0
		health.current_health = 1000000.0
		health.invincible = true
	queue_redraw()

func _set_boss_phase(phase: int) -> void:
	if not is_instance_valid(current_boss):
		return
	var health: Node = current_boss.get_node_or_null("HealthComponent")
	var data: Resource = current_boss.get("enemy_data") as Resource
	if health == null or data == null:
		return
	var layers: int = max(int(data.boss_health_bars), 1)
	phase = clampi(phase, 1, layers)
	var max_hp: float = health.get("max_health")
	var per_layer := max_hp / float(layers)
	var target_hp := max_hp - per_layer * float(phase - 1) - 1.0
	if phase == layers:
		target_hp = per_layer * 0.65
	target_hp = clampf(target_hp, 1.0, max_hp)
	health.set("current_health", target_hp)
	health.health_changed.emit(target_hp, max_hp)
	var controller := current_boss.get_node_or_null("BossSkillController")
	if controller != null and controller.has_method("cancel"):
		controller.call("cancel")
	AudioManager.play_sfx_by_key(&"button_click")

func spawn_enemy_at(data: Resource, spawn_position: Vector2) -> CharacterBody2D:
	if data == null or data.boss or not is_instance_valid(player_dummy):
		return null
	var enemy := EnemyScene.instantiate() as CharacterBody2D
	enemy.name = "%s_Summon" % data.enemy_id
	game_world.add_child(enemy)
	enemy.reset_for_spawn(data.duplicate(true), player_dummy, spawn_position)
	enemy.released.connect(_on_summon_released)
	summoned_enemies.append(enemy)
	return enemy

func get_active_enemies() -> Array:
	var enemies: Array = []
	if is_instance_valid(current_boss):
		enemies.append(current_boss)
	for enemy in summoned_enemies:
		if is_instance_valid(enemy):
			enemies.append(enemy)
	return enemies

func _on_summon_released(enemy: Node) -> void:
	summoned_enemies.erase(enemy)

func _clear_summons() -> void:
	for enemy in summoned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	summoned_enemies.clear()

func _get_live_summon_count() -> int:
	var count := 0
	for enemy in summoned_enemies:
		if is_instance_valid(enemy):
			count += 1
	return count

func _style_attack_button() -> void:
	attack_button.add_theme_stylebox_override("normal", _button_box(Color(0.7, 0.2, 0.15), Color(1.0, 0.6, 0.3)))
	attack_button.add_theme_stylebox_override("hover", _button_box(Color(0.8, 0.25, 0.2), Color(1.0, 0.75, 0.4)))
	attack_button.add_theme_stylebox_override("pressed", _button_box(Color(0.5, 0.15, 0.1), Color(0.8, 0.5, 0.25)))
	attack_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	attack_button.add_theme_font_size_override("font_size", 24)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(16)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 4)
	return box
