extends Node2D

const PlayerScene := preload("res://scenes/game/Player.tscn")
const HealUpgrade := preload("res://resources/upgrades/heal.tres")

const TEST_DAMAGE := 35.0
const AUTO_TEST_START_HEALTH := 50.0

@onready var game_world: Node2D = $GameWorld
@onready var camera: Camera2D = $Camera2D
@onready var game_ui: Control = $CanvasLayer/GameUI

var player: CharacterBody2D
var health_bar: ProgressBar
var health_label: Label
var cooldown_label: Label
var level_label: Label
var message_label: Label
var cast_button: Button
var damage_button: Button
var reset_health_button: Button
var reset_cooldown_button: Button
var upgrade_button: Button
var infinite_skill_button: Button
var infinite_skill_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	InputAdapter.reset_heal_cooldown()
	GameManager.player = null
	_spawn_player()
	_build_ui()
	_damage_player(AUTO_TEST_START_HEALTH, "Player starts injured so healing is visible.")
	_update_status()
	
	# 设置 process_priority = -10，让这个节点的 _process 更早运行，在 HealSkill.gd 之前
	set_process_priority(-10)
	
	if OS.get_cmdline_user_args().has("--auto-test"):
		_run_auto_test.call_deferred()

func _exit_tree() -> void:
	InputAdapter.clear_virtual_inputs()
	InputAdapter.reset_heal_cooldown()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.global_position = player.global_position
	if infinite_skill_enabled:
		_force_infinite_cooldown()
	_update_status()
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _draw() -> void:
	draw_rect(Rect2(-960, -540, 1920, 1080), Color("1d2b22"))
	draw_rect(Rect2(-960, 112, 1920, 180), Color("514d3b"))
	draw_circle(Vector2.ZERO, 112.0, Color(0.0, 0.0, 0.0, 0.18))
	draw_circle(Vector2.ZERO, 72.0, Color("2d4a3a"))

func _spawn_player() -> void:
	player = PlayerScene.instantiate() as CharacterBody2D
	player.name = "HealTestPlayer"
	player.global_position = Vector2.ZERO
	game_world.add_child(player)
	player.set_world_bounds(Rect2(-920, -500, 1840, 1000))
	player.ranged_weapon.firing_enabled = false
	player.orbit_flywheel.flywheel_count = 0
	player.drone_weapon.drone_unlocked = false
	player.health_component.health_changed.connect(_on_health_changed)

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 24.0
	panel.offset_top = 22.0
	panel.offset_right = 414.0
	panel.offset_bottom = 342.0
	panel.add_theme_stylebox_override("panel", _panel_box())
	game_ui.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Heal Skill Test"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("fff0c6"))
	box.add_child(title)

	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_color", Color("e9dfbe"))
	box.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(0, 26)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _bar_box(Color("1b1714"), Color("5f5240")))
	health_bar.add_theme_stylebox_override("fill", _bar_box(Color("39bf63"), Color("55d878")))
	box.add_child(health_bar)

	cooldown_label = Label.new()
	cooldown_label.add_theme_color_override("font_color", Color("d7c89b"))
	box.add_child(cooldown_label)

	level_label = Label.new()
	level_label.add_theme_color_override("font_color", Color("d7c89b"))
	box.add_child(level_label)

	message_label = Label.new()
	message_label.custom_minimum_size = Vector2(0, 46)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("b9d9b6"))
	box.add_child(message_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 10)
	buttons.add_theme_constant_override("v_separation", 8)
	box.add_child(buttons)

	damage_button = _make_button("Damage")
	damage_button.pressed.connect(_on_damage_pressed)
	buttons.add_child(damage_button)

	cast_button = _make_button("Cast Heal")
	cast_button.pressed.connect(_on_cast_pressed)
	buttons.add_child(cast_button)

	reset_health_button = _make_button("Reset HP")
	reset_health_button.pressed.connect(_on_reset_health_pressed)
	buttons.add_child(reset_health_button)

	reset_cooldown_button = _make_button("Reset CD")
	reset_cooldown_button.pressed.connect(_on_reset_cooldown_pressed)
	buttons.add_child(reset_cooldown_button)

	upgrade_button = _make_button("Upgrade")
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	buttons.add_child(upgrade_button)

	infinite_skill_button = _make_button("无限技能: 关")
	infinite_skill_button.pressed.connect(_on_infinite_skill_pressed)
	buttons.add_child(infinite_skill_button)

	var menu_button := _make_button("Main Menu")
	menu_button.pressed.connect(_on_menu_pressed)
	buttons.add_child(menu_button)

	var hint := Label.new()
	hint.text = "Use the bottom-right green icon to test the real virtual skill button."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("998966"))
	box.add_child(hint)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(165, 42)
	button.text = text
	button.add_theme_stylebox_override("normal", _button_box(Color("31412f"), Color("8d7754")))
	button.add_theme_stylebox_override("hover", _button_box(Color("42583f"), Color("bca268")))
	button.add_theme_stylebox_override("pressed", _button_box(Color("243023"), Color("6f5d41")))
	button.add_theme_stylebox_override("disabled", _button_box(Color("252721"), Color("555044")))
	button.add_theme_color_override("font_color", Color("f2dfb0"))
	button.add_theme_color_override("font_disabled_color", Color("877b65"))
	return button

func _on_damage_pressed() -> void:
	_damage_player(TEST_DAMAGE, "Damage applied. Now cast heal.")

func _on_infinite_skill_pressed() -> void:
	infinite_skill_enabled = not infinite_skill_enabled
	infinite_skill_button.text = "无限技能: 开" if infinite_skill_enabled else "无限技能: 关"
	if infinite_skill_enabled:
		_force_infinite_cooldown()
		_set_message("无限技能已开启：CD 每帧重置。")
	else:
		_set_message("无限技能已关闭。")

func _force_infinite_cooldown() -> void:
	var heal_skill := _get_heal_skill()
	if heal_skill != null:
		heal_skill.set("cooldown_remaining", 0.0)
	InputAdapter.reset_heal_cooldown()

func _on_cast_pressed() -> void:
	if not InputAdapter.is_heal_ready():
		_set_message("Heal is cooling down. Reset CD or wait.")
		return
	InputAdapter.request_virtual_heal()
	_set_message("Heal requested through InputAdapter.")

func _on_reset_health_pressed() -> void:
	var health := _get_health_component()
	if health == null:
		return
	health.reset()
	_set_message("Health reset to full.")

func _on_reset_cooldown_pressed() -> void:
	_reset_heal_cooldown()
	_set_message("Heal cooldown reset.")

func _on_upgrade_pressed() -> void:
	var heal_skill := _get_heal_skill()
	if heal_skill == null:
		return
	var current_level := int(heal_skill.get("upgrade_level"))
	if current_level >= HealUpgrade.max_level:
		_set_message("Heal is already at max test level.")
		return
	heal_skill.call("apply_upgrade", &"heal_level", 1.0)
	_set_message("Heal upgraded for this test.")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_health_changed(_current_health: float, _max_health: float) -> void:
	_update_status()

func _damage_player(amount: float, message: String = "") -> void:
	var health := _get_health_component()
	if health == null:
		return
	if health.current_health <= 1.0:
		health.reset()
	var safe_damage: float = minf(amount, maxf(0.0, health.current_health - 1.0))
	if safe_damage <= 0.0:
		return
	health.take_damage(safe_damage)
	if not message.is_empty():
		_set_message(message)

func _reset_heal_cooldown() -> void:
	var heal_skill := _get_heal_skill()
	if heal_skill != null:
		heal_skill.set("cooldown_remaining", 0.0)
	InputAdapter.reset_heal_cooldown()

func _update_status() -> void:
	var health := _get_health_component()
	if health == null or health_bar == null:
		return
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	health_label.text = "Health: %d / %d" % [int(health.current_health), int(health.max_health)]

	var remaining := InputAdapter.get_heal_cooldown_remaining()
	var duration := InputAdapter.get_heal_cooldown_duration()
	if remaining <= 0.0:
		cooldown_label.text = "Cooldown: READY"
	else:
		cooldown_label.text = "Cooldown: %.1fs / %.1fs" % [remaining, duration]

	var heal_skill := _get_heal_skill()
	if heal_skill != null:
		var skill_level := int(heal_skill.get("upgrade_level"))
		var heal_percent := float(heal_skill.get("base_heal_percent")) + 0.08 * float(skill_level)
		level_label.text = "Heal level: %d   Amount: %d%% max HP" % [skill_level, int(heal_percent * 100.0)]
		upgrade_button.disabled = skill_level >= HealUpgrade.max_level

	cast_button.disabled = not infinite_skill_enabled and remaining > 0.0

func _set_message(message: String) -> void:
	if message_label != null:
		message_label.text = message

func _get_health_component() -> Node:
	if not is_instance_valid(player):
		return null
	return player.get_node_or_null("HealthComponent")

func _get_heal_skill() -> Node:
	if not is_instance_valid(player):
		return null
	return player.get_node_or_null("WeaponsNode/HealSkill")

func _run_auto_test() -> void:
	var health := _get_health_component()
	if health == null:
		print("HEAL_SKILL_TEST result=FAIL reason=no_health_component")
		get_tree().quit(1)
		return
	health.current_health = AUTO_TEST_START_HEALTH
	health.health_changed.emit(health.current_health, health.max_health)
	_reset_heal_cooldown()
	var before: float = float(health.current_health)
	InputAdapter.request_virtual_heal()
	await get_tree().process_frame
	await get_tree().process_frame
	var after: float = float(health.current_health)
	var cooldown: float = InputAdapter.get_heal_cooldown_remaining()
	var passed: bool = after > before and cooldown > 0.0
	print("HEAL_SKILL_TEST before=%.1f after=%.1f cooldown=%.1f result=%s" % [before, after, cooldown, "PASS" if passed else "FAIL"])
	get_tree().quit(0 if passed else 1)

func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.052, 0.046, 0.94)
	box.border_color = Color("8d7754")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(12)
	return box

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(5)
	box.set_content_margin_all(8)
	return box

func _bar_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	return box
