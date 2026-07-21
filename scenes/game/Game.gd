extends Node

const VICTORY_EMBLEM := preload("res://assets/images/ui/emblem_victory.png")
const DEFEAT_EMBLEM := preload("res://assets/images/ui/emblem_defeat.png")
const ICON_RIFLE := preload("res://assets/images/weapons/old_rifle_128.png")
const ICON_FLYWHEEL := preload("res://assets/images/weapons/weapon_orbit_flywheel.png")
const ICON_DRONE := preload("res://assets/images/weapons/weapon_combat_drone.png")
const ICON_HEALTH := preload("res://assets/images/ui/icons/health.svg")
const ICON_LEVEL := preload("res://assets/images/ui/icons/level.svg")
const ICON_PAUSE := preload("res://assets/images/ui/icons/pause.svg")
const ICON_PROJECTILE := preload("res://assets/images/projectiles/bullet_player.png")
const ICON_REFRESH := preload("res://assets/images/ui/icons/refresh.svg")
const ICON_SCATTER := preload("res://assets/images/projectiles/projectile_wizard_orb.png")
const UPGRADE_ICON_MAX_SIZE := Vector2i(92, 92)
const BUTTON_TEXT_COLOR := Color("f2dfb0")
const BUTTON_DISABLED_TEXT_COLOR := Color("998966")

@export var run_duration: float = 720.0

@onready var game_world: Node2D = $GameWorld
@onready var world_map: Node2D = $GameWorld/WorldMap
@onready var enemy_spawner = $EnemySpawner
@onready var camera: Camera2D = $Camera2D
@onready var status_panel_bg: PanelContainer = $CanvasLayer/GameUI/StatusPanelBg
@onready var health_label: Label = $CanvasLayer/GameUI/TopHUD/HealthRow/HealthLabel
@onready var exp_bar: ProgressBar = $CanvasLayer/GameUI/ExpHUD/ExpBar
@onready var level_label: Label = $CanvasLayer/GameUI/ExpHUD/LevelLabel
@onready var time_label: Label = $CanvasLayer/GameUI/TopHUD/TimeRow/TimeLabel
@onready var kill_label: Label = $CanvasLayer/GameUI/TopHUD/KillRow/KillValueLabel
@onready var objective_label: Label = $CanvasLayer/GameUI/ObjectiveLabel
@onready var pause_button: Button = $CanvasLayer/GameUI/PauseButton
@onready var game_over_screen: Control = $CanvasLayer/GameUI/GameOverScreen
@onready var result_emblem: TextureRect = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/ResultEmblem
@onready var result_label: Label = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/ResultLabel
@onready var summary_label: Label = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/SummaryLabel
@onready var restart_button: Button = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/RestartButton
@onready var next_button: Button = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/NextButton
@onready var level_select_button: Button = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/LevelSelectButton
@onready var home_button: Button = $CanvasLayer/GameUI/GameOverScreen/Panel/VBox/HomeButton
@onready var pause_screen: Control = $CanvasLayer/GameUI/PauseScreen
@onready var resume_button: Button = $CanvasLayer/GameUI/PauseScreen/Panel/VBox/ResumeButton
@onready var pause_restart_button: Button = $CanvasLayer/GameUI/PauseScreen/Panel/VBox/RestartButton
@onready var pause_level_select_button: Button = $CanvasLayer/GameUI/PauseScreen/Panel/VBox/LevelSelectButton
@onready var pause_home_button: Button = $CanvasLayer/GameUI/PauseScreen/Panel/VBox/HomeButton
@onready var upgrade_screen: Control = $CanvasLayer/GameUI/UpgradeScreen
@onready var upgrade_buttons: Array[Button] = [
	$CanvasLayer/GameUI/UpgradeScreen/Panel/VBox/Choices/Choice1,
	$CanvasLayer/GameUI/UpgradeScreen/Panel/VBox/Choices/Choice2,
	$CanvasLayer/GameUI/UpgradeScreen/Panel/VBox/Choices/Choice3
]
@onready var upgrade_refresh_button: Button = $CanvasLayer/GameUI/UpgradeScreen/Panel/VBox/RefreshButton

var player: CharacterBody2D
var manual_pause: bool = false
var upgrade_pending: int = 0
var current_choices: Array[Resource] = []
var upgrade_refresh_used: bool = false
var upgrade_levels: Dictionary = {}
var boss_is_defeated: bool = false
var boss_music_started: bool = false
var smoke_test: bool = false
var smoke_boss_marked: bool = false
var stress_test: bool = false
var stress_elapsed: float = 0.0
var timeline_test: bool = false
var boss_pool_test: bool = false
var upgrade_exhaustion_test: bool = false
var level_data: Resource
var camera_shake_strength: float = 0.0
var upgrade_icon_cache: Dictionary = {}

var upgrade_catalog: Array[Resource] = [
	preload("res://resources/upgrades/damage.tres"),
	preload("res://resources/upgrades/fire_rate.tres"),
	preload("res://resources/upgrades/pierce.tres"),
	preload("res://resources/upgrades/projectiles.tres"),
	preload("res://resources/upgrades/scatter_blossom.tres"),
	preload("res://resources/upgrades/flywheel.tres"),
	preload("res://resources/upgrades/drone.tres"),
	preload("res://resources/upgrades/range.tres"),
	preload("res://resources/upgrades/move_speed.tres"),
	preload("res://resources/upgrades/max_health.tres")
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	smoke_test = OS.get_cmdline_user_args().has("--smoke-test")
	stress_test = OS.get_cmdline_user_args().has("--stress-test")
	timeline_test = OS.get_cmdline_user_args().has("--timeline-test")
	boss_pool_test = OS.get_cmdline_user_args().has("--boss-pool-test")
	upgrade_exhaustion_test = OS.get_cmdline_user_args().has("--upgrade-exhaustion-test")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			var requested_level := GameManager.get_level_by_id(StringName(argument.trim_prefix("--level=")))
			if requested_level != null:
				GameManager.select_level(requested_level)
	level_data = GameManager.selected_level
	if level_data != null:
		run_duration = level_data.duration
	if smoke_test:
		run_duration = 5.0
	_connect_signals()
	_apply_overlay_style()
	_start_game()

func _process(delta: float) -> void:
	if GameManager.run_active and not get_tree().paused:
		var clock_delta := delta * 120.0 if timeline_test else delta
		GameManager.update_game_time(clock_delta)
		if smoke_test:
			_run_smoke_flow()
		if stress_test:
			_run_stress_flow(delta)
		if timeline_test and GameManager.game_time >= enemy_spawner.boss_spawn_time + 5.0:
			boss_is_defeated = true
		if not boss_music_started and GameManager.game_time >= enemy_spawner.boss_spawn_time:
			boss_music_started = true
			AudioManager.play_sfx_by_key(&"boss_warning")
			AudioManager.play_music_by_key(&"boss")
		if boss_is_defeated and GameManager.game_time >= run_duration:
			GameManager.finish_run(&"victory")
	_update_ui()
	if is_instance_valid(player):
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 24.0)
		camera.global_position = player.global_position + Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))

func shake_camera(strength: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)

func _apply_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = floori(bounds.position.x)
	camera.limit_top = floori(bounds.position.y)
	camera.limit_right = ceili(bounds.end.x)
	camera.limit_bottom = ceili(bounds.end.y)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_toggle_manual_pause()
		get_viewport().set_input_as_handled()

func _connect_signals() -> void:
	pause_button.pressed.connect(_toggle_manual_pause)
	resume_button.pressed.connect(_toggle_manual_pause)
	restart_button.pressed.connect(_restart)
	next_button.pressed.connect(_start_next_level)
	level_select_button.pressed.connect(_return_to_level_select)
	home_button.pressed.connect(_return_home)
	pause_restart_button.pressed.connect(_restart)
	pause_level_select_button.pressed.connect(_return_to_level_select)
	pause_home_button.pressed.connect(_return_home)
	GameManager.level_up.connect(_on_level_up)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.boss_defeated.connect(_on_boss_defeated)
	upgrade_refresh_button.pressed.connect(_refresh_upgrade_choices)
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_choose_upgrade.bind(index))

func _start_game() -> void:
	game_over_screen.visible = false
	pause_screen.visible = false
	upgrade_screen.visible = false
	manual_pause = false
	boss_is_defeated = false
	boss_music_started = false
	upgrade_pending = 0
	upgrade_refresh_used = false
	upgrade_levels.clear()
	InputAdapter.clear_virtual_inputs()
	InputAdapter.reset_dash_cooldown()
	InputAdapter.reset_scatter_cooldown()
	GameManager.start_run(level_data)
	player = preload("res://scenes/game/Player.tscn").instantiate()
	player.global_position = Vector2.ZERO
	game_world.add_child(player)
	world_map.configure(level_data)
	var world_bounds: Rect2 = world_map.get_world_bounds()
	player.set_world_bounds(world_bounds)
	_apply_camera_limits(world_bounds)
	enemy_spawner.configure(level_data, player, world_map, game_world)
	if smoke_test:
		enemy_spawner.boss_spawn_time = 2.0
	enemy_spawner.start_spawning()
	if boss_pool_test:
		_run_boss_pool_test()
	if upgrade_exhaustion_test:
		_run_upgrade_exhaustion_test()
	if stress_test:
		GameManager.game_time = 600.0
		var stress_enemy: Resource = preload("res://resources/enemies/bandit.tres")
		for index in enemy_spawner.active_enemy_limit:
			enemy_spawner.spawn_enemy(stress_enemy)
	AudioManager.play_music_by_key(&"battle")

func _toggle_manual_pause() -> void:
	if not GameManager.run_active or upgrade_screen.visible:
		return
	manual_pause = not manual_pause
	AudioManager.play_ui_by_key(&"pause" if manual_pause else &"resume")
	pause_screen.visible = manual_pause
	InputAdapter.clear_virtual_inputs()
	get_tree().paused = manual_pause

func _on_level_up(_level: int) -> void:
	AudioManager.play_sfx_by_key(&"level_up")
	upgrade_pending += 1
	if not upgrade_screen.visible:
		_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	if not _roll_upgrade_choices(false):
		upgrade_pending = 0
		current_choices.clear()
		upgrade_screen.visible = false
		get_tree().paused = manual_pause
		return
	upgrade_refresh_used = false
	_update_refresh_button()
	upgrade_screen.visible = true
	AudioManager.play_sfx_by_key(&"upgrade_panel_open")
	InputAdapter.clear_virtual_inputs()
	get_tree().paused = true
	if smoke_test:
		_choose_upgrade.call_deferred(0)

func _is_upgrade_available(upgrade: Resource) -> bool:
	if int(upgrade_levels.get(upgrade.upgrade_id, 0)) >= upgrade.max_level:
		return false
	if String(upgrade.upgrade_id).begins_with("drone_") and int(upgrade_levels.get(&"drone", 0)) <= 0:
		return false
	return true

func _choose_upgrade(index: int) -> void:
	if index < 0 or index >= current_choices.size() or not is_instance_valid(player):
		AudioManager.play_ui_by_key(&"invalid")
		return
	var choice := current_choices[index]
	upgrade_levels[choice.upgrade_id] = int(upgrade_levels.get(choice.upgrade_id, 0)) + 1
	player.apply_upgrade(choice)
	if choice.upgrade_id == &"flywheel" or choice.upgrade_id == &"drone":
		AudioManager.play_sfx_by_key(&"weapon_unlock")
	else:
		AudioManager.play_sfx_by_key(&"upgrade_select")
	upgrade_pending = maxi(0, upgrade_pending - 1)
	if upgrade_pending > 0:
		_show_upgrade_choices()
	else:
		upgrade_screen.visible = false
		get_tree().paused = manual_pause

func _refresh_upgrade_choices() -> void:
	if upgrade_refresh_used:
		AudioManager.play_ui_by_key(&"invalid")
		return
	upgrade_refresh_used = true
	if not _roll_upgrade_choices(true):
		AudioManager.play_ui_by_key(&"invalid")
	_update_refresh_button()
	AudioManager.play_sfx_by_key(&"upgrade_panel_open", -4.0)

func _roll_upgrade_choices(avoid_current: bool) -> bool:
	var available := _get_available_upgrades()
	if available.is_empty():
		return false
	var previous_ids := {}
	if avoid_current:
		for choice in current_choices:
			previous_ids[choice.upgrade_id] = true
	available.shuffle()
	current_choices.clear()
	var target_count := mini(upgrade_buttons.size(), available.size())
	if avoid_current and available.size() > target_count:
		for upgrade in available:
			if previous_ids.has(upgrade.upgrade_id):
				continue
			current_choices.append(upgrade)
			if current_choices.size() >= target_count:
				break
	for upgrade in available:
		if current_choices.size() >= target_count:
			break
		if current_choices.has(upgrade):
			continue
		current_choices.append(upgrade)
	_update_upgrade_buttons()
	return true

func _get_available_upgrades() -> Array[Resource]:
	var available: Array[Resource] = []
	for upgrade in upgrade_catalog:
		if _is_upgrade_available(upgrade):
			available.append(upgrade)
	return available

func _update_upgrade_buttons() -> void:
	for index in upgrade_buttons.size():
		var button := upgrade_buttons[index]
		if index < current_choices.size():
			var choice := current_choices[index]
			var next_level := int(upgrade_levels.get(choice.upgrade_id, 0)) + 1
			_set_upgrade_button_content(button, choice, next_level)
			button.visible = true
		else:
			_clear_upgrade_button(button)

func _set_upgrade_button_content(button: Button, choice: Resource, next_level: int) -> void:
	button.text = ""
	button.icon = null
	var tier := _get_upgrade_tier(next_level, choice.max_level)
	var palette := _get_upgrade_palette(tier)
	_apply_upgrade_button_palette(button, palette)
	_ensure_upgrade_card_nodes(button)
	var title_label := button.get_node("Card/CardBox/Title") as Label
	var icon_frame := button.get_node("Card/CardBox/IconFrame") as PanelContainer
	var icon_rect := button.get_node("Card/CardBox/IconFrame/Icon") as TextureRect
	var stars_label := button.get_node("Card/CardBox/Stars") as Label
	var type_label := button.get_node("Card/CardBox/Type") as Label
	var desc_label := button.get_node("Card/CardBox/Description") as Label
	title_label.text = choice.title
	icon_frame.add_theme_stylebox_override("panel", _upgrade_icon_frame_box(palette["frame"], palette["border"]))
	icon_rect.texture = _get_fitted_upgrade_icon(choice)
	stars_label.text = _build_star_text(next_level, choice.max_level)
	stars_label.add_theme_color_override("font_color", palette["accent"])
	type_label.text = "%s  Lv.%d/%d" % [_get_upgrade_type(choice), next_level, choice.max_level]
	type_label.add_theme_color_override("font_color", palette["accent"])
	desc_label.text = choice.description

func _clear_upgrade_button(button: Button) -> void:
	button.visible = false
	button.text = ""
	button.icon = null

func _update_refresh_button() -> void:
	var available_count := _get_available_upgrades().size()
	var can_refresh := not upgrade_refresh_used and available_count > current_choices.size()
	upgrade_refresh_button.disabled = not can_refresh
	if upgrade_refresh_used:
		_set_centered_button_label(upgrade_refresh_button, "本次已刷新")
	elif can_refresh:
		_set_centered_button_label(upgrade_refresh_button, "刷新技能")
	else:
		_set_centered_button_label(upgrade_refresh_button, "没有可刷新技能")

func _get_upgrade_tier(next_level: int, max_level: int) -> int:
	if max_level <= 1:
		return 4
	var ratio := float(next_level) / float(max_level)
	if ratio >= 1.0:
		return 4
	if ratio >= 0.75:
		return 3
	if ratio >= 0.5:
		return 2
	return 1

func _get_upgrade_palette(tier: int) -> Dictionary:
	match tier:
		4:
			return {"fill": Color("22162e"), "border": Color("f3cf78"), "accent": Color("ffe18f"), "frame": Color("3b2749")}
		3:
			return {"fill": Color("10272b"), "border": Color("5fd1c8"), "accent": Color("a8fff5"), "frame": Color("173941")}
		2:
			return {"fill": Color("122818"), "border": Color("72bf6a"), "accent": Color("bdf49a"), "frame": Color("1d3b24")}
		_:
			return {"fill": Color("1d1810"), "border": Color("a98955"), "accent": Color("f2dfb0"), "frame": Color("2c2418")}

func _apply_upgrade_button_palette(button: Button, palette: Dictionary) -> void:
	var fill: Color = palette["fill"]
	var border: Color = palette["border"]
	var accent: Color = palette["accent"]
	button.add_theme_stylebox_override("normal", _upgrade_card_box(fill, border))
	button.add_theme_stylebox_override("hover", _upgrade_card_box(fill.lightened(0.08), accent))
	button.add_theme_stylebox_override("pressed", _upgrade_card_box(fill.darkened(0.08), border.darkened(0.12)))

func _get_upgrade_type(upgrade: Resource) -> String:
	match upgrade.upgrade_id:
		&"flywheel", &"drone":
			return "装备"
		&"drone_damage", &"drone_fire_rate", &"drone_range":
			return "无人机"
		&"scatter_blossom":
			return "技能"
		&"damage", &"fire_rate", &"range", &"pierce", &"projectiles":
			return "步枪"
		&"move_speed", &"max_health":
			return "生存"
		_:
			return "技能"

func _build_star_text(next_level: int, max_level: int) -> String:
	var text := ""
	for index in max_level:
		text += "★" if index < next_level else "☆"
	return text

func _on_boss_defeated() -> void:
	boss_is_defeated = true

func _on_game_ended(result: StringName) -> void:
	enemy_spawner.stop_spawning()
	InputAdapter.clear_virtual_inputs()
	AudioManager.stop_music()
	AudioManager.play_sfx_by_key(&"victory" if result == &"victory" else &"defeat")
	get_tree().paused = true
	pause_screen.visible = false
	upgrade_screen.visible = false
	game_over_screen.visible = true
	result_emblem.texture = VICTORY_EMBLEM if result == &"victory" else DEFEAT_EMBLEM
	var next_level := GameManager.get_next_level()
	next_button.visible = result == &"victory" and next_level != null
	result_label.text = "任务完成" if result == &"victory" else "守卫倒下"
	summary_label.text = "%s\n坚持时间  %s\n击败敌人  %d\n守卫等级  %d" % [level_data.title, _format_time(GameManager.game_time), GameManager.kill_count, GameManager.current_level]
	if timeline_test:
		print("TIMELINE_TEST level=%s time=%.1f boss_spawned=%s result=%s" % [level_data.level_id, GameManager.game_time, enemy_spawner.boss_spawned, result])
		get_tree().create_timer(0.2, true).timeout.connect(func(): get_tree().quit())
	elif smoke_test:
		print("SMOKE_TEST level=%s result=%s" % [level_data.level_id, result])
		get_tree().create_timer(0.2, true).timeout.connect(func(): get_tree().quit())

func _update_ui() -> void:
	if is_instance_valid(player):
		health_label.text = "生命 %d / %d" % [int(player.health_component.current_health), int(player.health_component.max_health)]
	exp_bar.max_value = GameManager.exp_to_next_level
	exp_bar.value = GameManager.current_exp
	level_label.text = "等级 %d" % GameManager.current_level
	time_label.text = "%s / %s" % [_format_time(GameManager.game_time), _format_time(run_duration)]
	kill_label.text = "击杀 %d" % GameManager.kill_count
	_update_objective_label()

func _update_objective_label() -> void:
	if GameManager.game_time < enemy_spawner.boss_spawn_time:
		objective_label.text = "任务：坚持到%s出现" % level_data.boss_data.display_name
	elif not boss_is_defeated:
		objective_label.text = "任务：击败%s" % level_data.boss_data.display_name
	else:
		objective_label.text = "任务：坚持到撤离时间"

func _format_time(value: float) -> String:
	var total := maxi(0, int(value))
	return "%02d:%02d" % [total / 60, total % 60]

func _restart() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _start_next_level() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	var next_level := GameManager.get_next_level()
	if next_level == null:
		_return_to_level_select()
		return
	get_tree().paused = false
	GameManager.select_level(next_level)
	get_tree().reload_current_scene()

func _return_to_level_select() -> void:
	AudioManager.play_ui_by_key(&"back")
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _return_home() -> void:
	AudioManager.play_ui_by_key(&"back")
	get_tree().paused = false
	InputAdapter.clear_virtual_inputs()
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _run_smoke_flow() -> void:
	if GameManager.game_time >= 0.8 and GameManager.current_level == 1:
		GameManager.add_exp(10)
	if GameManager.game_time >= 3.0 and not smoke_boss_marked:
		smoke_boss_marked = true
		boss_is_defeated = true

func _run_stress_flow(delta: float) -> void:
	stress_elapsed += delta
	if stress_elapsed < 8.0:
		return
	var active_bullets: int = player.ranged_weapon.get_active_bullet_count()
	var active_scatter_orbs: int = player.blossom_scatter.get_active_orb_count()
	var active_orbs: int = $GameWorld/ExperiencePool.get_active_orb_count()
	var enemy_bullets: int = $GameWorld/EnemyProjectilePool.get_active_count()
	print("STRESS_TEST enemies=%d bullets=%d scatter=%d enemy_bullets=%d orbs=%d pool_limit=%d" % [enemy_spawner.get_active_enemy_count(), active_bullets, active_scatter_orbs, enemy_bullets, active_orbs, enemy_spawner.active_enemy_limit])
	get_tree().quit()

func _run_boss_pool_test() -> void:
	var ordinary_enemy: Resource = level_data.enemy_catalog[0]
	for index in enemy_spawner.pool_size:
		enemy_spawner.spawn_enemy(ordinary_enemy)
	var spawned: bool = enemy_spawner.spawn_enemy(level_data.boss_data)
	print("BOSS_POOL_TEST pool_exhausted=%s boss_spawned=%s active=%d" % [enemy_spawner.inactive_pool.is_empty(), spawned, enemy_spawner.get_active_enemy_count()])
	get_tree().create_timer(0.1, true).timeout.connect(func(): get_tree().quit())

func _run_upgrade_exhaustion_test() -> void:
	for upgrade in upgrade_catalog:
		upgrade_levels[upgrade.upgrade_id] = upgrade.max_level
	upgrade_pending = 1
	_show_upgrade_choices()
	print("UPGRADE_EXHAUSTION_TEST pending=%d screen_visible=%s paused=%s" % [upgrade_pending, upgrade_screen.visible, get_tree().paused])
	get_tree().create_timer(0.1, true).timeout.connect(func(): get_tree().quit())

func _apply_overlay_style() -> void:
	status_panel_bg.add_theme_stylebox_override("panel", _status_panel_box())
	_style_exp_bar(exp_bar)
	pause_button.text = ""
	pause_button.icon = ICON_PAUSE
	pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_button.add_theme_constant_override("icon_max_width", 28)
	_set_centered_button_content(upgrade_refresh_button, ICON_REFRESH, 24, 10, 18)
	for panel_path in ["CanvasLayer/GameUI/GameOverScreen/Panel", "CanvasLayer/GameUI/PauseScreen/Panel", "CanvasLayer/GameUI/UpgradeScreen/Panel"]:
		var panel := get_node_or_null(panel_path) as PanelContainer
		if panel != null:
			panel.add_theme_stylebox_override("panel", _panel_box())
	for button in [pause_button, restart_button, next_button, level_select_button, home_button, resume_button, pause_restart_button, pause_level_select_button, pause_home_button, upgrade_refresh_button]:
		_style_game_button(button)
	for button in upgrade_buttons:
		_style_upgrade_button(button)

func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.064, 0.052, 0.94)
	box.border_color = Color("b99a58")
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(20)
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 14
	box.shadow_offset = Vector2(0, 5)
	return box

func _style_exp_bar(bar: ProgressBar) -> void:
	bar.add_theme_stylebox_override("background", _bar_box(Color(0.0, 0.0, 0.0, 0.92), Color("2b2113"), 10))
	bar.add_theme_stylebox_override("fill", _bar_box(Color("f1bd32"), Color("f1bd32"), 10))

func _bar_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _status_panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.025, 0.02, 0.68)
	box.border_color = Color(0.95, 0.74, 0.34, 0.28)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	return box

func _style_game_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_box(Color("4b3428"), Color("a98955")))
	button.add_theme_stylebox_override("hover", _button_box(Color("6a432d"), Color("d0ad68")))
	button.add_theme_stylebox_override("pressed", _button_box(Color("31251f"), Color("7e6846")))
	button.add_theme_stylebox_override("disabled", _button_box(Color("2e2a24"), Color("665a43")))
	button.add_theme_color_override("font_color", Color("f2dfb0"))
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_color_override("font_disabled_color", Color("998966"))

func _set_centered_button_content(button: Button, texture: Texture2D, icon_size: int, gap: int, font_size: int) -> void:
	var label_text := button.text
	button.text = ""
	button.icon = null

	var content := HBoxContainer.new()
	content.name = "CenteredContent"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", gap)
	button.add_child(content)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var label := Label.new()
	label.name = "Text"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	content.add_child(label)

	_set_centered_button_label(button, label_text)

func _set_centered_button_label(button: Button, label_text: String) -> void:
	var label := button.get_node_or_null("CenteredContent/Text") as Label
	if label == null:
		button.text = label_text
		return
	button.text = ""
	label.text = label_text
	var text_color := BUTTON_DISABLED_TEXT_COLOR if button.disabled else BUTTON_TEXT_COLOR
	label.add_theme_color_override("font_color", text_color)

func _style_upgrade_button(button: Button) -> void:
	_ensure_upgrade_card_nodes(button)
	button.add_theme_stylebox_override("normal", _upgrade_card_box(Color(0.115, 0.093, 0.064, 0.96), Color("a98955")))
	button.add_theme_stylebox_override("hover", _upgrade_card_box(Color(0.18, 0.125, 0.072, 0.98), Color("f0c66a")))
	button.add_theme_stylebox_override("pressed", _upgrade_card_box(Color(0.075, 0.063, 0.052, 0.98), Color("7e6846")))
	button.add_theme_color_override("font_color", Color("f5e6be"))
	button.add_theme_color_override("font_hover_color", Color("fff3ca"))
	button.add_theme_color_override("font_pressed_color", Color("ead098"))
	button.add_theme_font_size_override("font_size", 19)
	button.clip_contents = true

func _ensure_upgrade_card_nodes(button: Button) -> void:
	if button.has_node("Card"):
		return
	var card := MarginContainer.new()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_theme_constant_override("margin_left", 16)
	card.add_theme_constant_override("margin_top", 14)
	card.add_theme_constant_override("margin_right", 16)
	card.add_theme_constant_override("margin_bottom", 14)
	button.add_child(card)

	var box := VBoxContainer.new()
	box.name = "CardBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.custom_minimum_size = Vector2(0, 46)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color("fff0c6"))
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	var icon_frame := PanelContainer.new()
	icon_frame.name = "IconFrame"
	icon_frame.custom_minimum_size = Vector2(0, 126)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(0, 108)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_frame.add_child(icon)

	var stars := Label.new()
	stars.name = "Stars"
	stars.custom_minimum_size = Vector2(0, 28)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 22)
	box.add_child(stars)

	var type_label := Label.new()
	type_label.name = "Type"
	type_label.custom_minimum_size = Vector2(0, 26)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 16)
	box.add_child(type_label)

	var description := Label.new()
	description.name = "Description"
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color("efe0bb"))
	description.add_theme_font_size_override("font_size", 16)
	box.add_child(description)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(5)
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.34)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	return box

func _upgrade_card_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(18)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 12
	box.shadow_offset = Vector2(0, 4)
	return box

func _upgrade_icon_frame_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(8)
	return box

func _get_upgrade_icon(upgrade: Resource) -> Texture2D:
	match upgrade.upgrade_id:
		&"damage", &"fire_rate", &"range", &"pierce":
			return ICON_RIFLE
		&"projectiles":
			return ICON_PROJECTILE
		&"scatter_blossom":
			return ICON_SCATTER
		&"flywheel":
			return ICON_FLYWHEEL
		&"drone", &"drone_damage", &"drone_fire_rate", &"drone_range":
			return ICON_DRONE
		&"move_speed":
			return ICON_LEVEL
		&"max_health":
			return ICON_HEALTH
		_:
			return ICON_LEVEL

func _get_fitted_upgrade_icon(upgrade: Resource) -> Texture2D:
	var source := _get_upgrade_icon(upgrade)
	var cache_key := "%s:%dx%d" % [source.resource_path, UPGRADE_ICON_MAX_SIZE.x, UPGRADE_ICON_MAX_SIZE.y]
	if upgrade_icon_cache.has(cache_key):
		return upgrade_icon_cache[cache_key]
	var fitted := _fit_texture_to_max_size(source, UPGRADE_ICON_MAX_SIZE)
	upgrade_icon_cache[cache_key] = fitted
	return fitted

func _fit_texture_to_max_size(texture: Texture2D, max_size: Vector2i) -> Texture2D:
	if texture == null:
		return null
	var source_size := texture.get_size()
	if source_size.x <= max_size.x and source_size.y <= max_size.y:
		return texture
	var scale := minf(float(max_size.x) / source_size.x, float(max_size.y) / source_size.y)
	var fitted_size := Vector2i(maxi(1, int(source_size.x * scale)), maxi(1, int(source_size.y * scale)))
	var image := texture.get_image()
	image.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)
