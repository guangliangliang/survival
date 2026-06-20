extends Node

@export var run_duration: float = 720.0

@onready var game_world: Node2D = $GameWorld
@onready var world_map: Node2D = $GameWorld/WorldMap
@onready var enemy_spawner = $EnemySpawner
@onready var camera: Camera2D = $Camera2D
@onready var health_bar: ProgressBar = $CanvasLayer/GameUI/TopHUD/HealthBar
@onready var health_label: Label = $CanvasLayer/GameUI/TopHUD/HealthLabel
@onready var exp_bar: ProgressBar = $CanvasLayer/GameUI/TopHUD/ExpBar
@onready var exp_label: Label = $CanvasLayer/GameUI/TopHUD/ExpLabel
@onready var time_label: Label = $CanvasLayer/GameUI/TopHUD/TimeLabel
@onready var kill_label: Label = $CanvasLayer/GameUI/TopHUD/KillLabel
@onready var objective_label: Label = $CanvasLayer/GameUI/TopHUD/ObjectiveLabel
@onready var pause_button: Button = $CanvasLayer/GameUI/PauseButton
@onready var game_over_screen: Control = $CanvasLayer/GameUI/GameOverScreen
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

var player: CharacterBody2D
var manual_pause: bool = false
var upgrade_pending: int = 0
var current_choices: Array[Resource] = []
var upgrade_levels: Dictionary = {}
var boss_is_defeated: bool = false
var smoke_test: bool = false
var smoke_boss_marked: bool = false
var stress_test: bool = false
var stress_elapsed: float = 0.0
var timeline_test: bool = false
var boss_pool_test: bool = false
var upgrade_exhaustion_test: bool = false
var level_data: Resource
var camera_shake_strength: float = 0.0

var upgrade_catalog: Array[Resource] = [
	preload("res://resources/upgrades/damage.tres"),
	preload("res://resources/upgrades/fire_rate.tres"),
	preload("res://resources/upgrades/pierce.tres"),
	preload("res://resources/upgrades/projectiles.tres"),
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
		if boss_is_defeated and GameManager.game_time >= run_duration:
			GameManager.finish_run(&"victory")
	_update_ui()
	if is_instance_valid(player):
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 24.0)
		camera.global_position = player.global_position + Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))

func shake_camera(strength: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)

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
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_choose_upgrade.bind(index))

func _start_game() -> void:
	game_over_screen.visible = false
	pause_screen.visible = false
	upgrade_screen.visible = false
	manual_pause = false
	boss_is_defeated = false
	upgrade_pending = 0
	upgrade_levels.clear()
	InputAdapter.clear_virtual_move()
	GameManager.start_run(level_data)
	player = preload("res://scenes/game/Player.tscn").instantiate()
	player.global_position = Vector2.ZERO
	game_world.add_child(player)
	world_map.configure(level_data)
	player.set_world_bounds(world_map.get_world_bounds())
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

func _toggle_manual_pause() -> void:
	if not GameManager.run_active or upgrade_screen.visible:
		return
	manual_pause = not manual_pause
	pause_screen.visible = manual_pause
	InputAdapter.clear_virtual_move()
	get_tree().paused = manual_pause

func _on_level_up(_level: int) -> void:
	upgrade_pending += 1
	if not upgrade_screen.visible:
		_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	var available: Array[Resource] = []
	for upgrade in upgrade_catalog:
		if int(upgrade_levels.get(upgrade.upgrade_id, 0)) < upgrade.max_level:
			available.append(upgrade)
	if available.is_empty():
		upgrade_pending = 0
		current_choices.clear()
		upgrade_screen.visible = false
		get_tree().paused = manual_pause
		return
	available.shuffle()
	current_choices.clear()
	for index in mini(3, available.size()):
		current_choices.append(available[index])
	for index in upgrade_buttons.size():
		var button := upgrade_buttons[index]
		if index < current_choices.size():
			var choice := current_choices[index]
			var next_level := int(upgrade_levels.get(choice.upgrade_id, 0)) + 1
			button.text = "%s  Lv.%d\n%s" % [choice.title, next_level, choice.description]
			button.visible = true
		else:
			button.visible = false
	upgrade_screen.visible = true
	InputAdapter.clear_virtual_move()
	get_tree().paused = true
	if smoke_test:
		_choose_upgrade.call_deferred(0)

func _choose_upgrade(index: int) -> void:
	if index < 0 or index >= current_choices.size() or not is_instance_valid(player):
		return
	var choice := current_choices[index]
	upgrade_levels[choice.upgrade_id] = int(upgrade_levels.get(choice.upgrade_id, 0)) + 1
	player.apply_upgrade(choice)
	upgrade_pending = maxi(0, upgrade_pending - 1)
	if upgrade_pending > 0:
		_show_upgrade_choices()
	else:
		upgrade_screen.visible = false
		get_tree().paused = manual_pause

func _on_boss_defeated() -> void:
	boss_is_defeated = true

func _on_game_ended(result: StringName) -> void:
	enemy_spawner.stop_spawning()
	InputAdapter.clear_virtual_move()
	get_tree().paused = true
	pause_screen.visible = false
	upgrade_screen.visible = false
	game_over_screen.visible = true
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
		health_bar.max_value = player.health_component.max_health
		health_bar.value = player.health_component.current_health
		health_label.text = "生命 %d / %d" % [int(player.health_component.current_health), int(player.health_component.max_health)]
	exp_bar.max_value = GameManager.exp_to_next_level
	exp_bar.value = GameManager.current_exp
	exp_label.text = "等级 %d   经验 %d / %d" % [GameManager.current_level, GameManager.current_exp, GameManager.exp_to_next_level]
	time_label.text = "%s / %s" % [_format_time(GameManager.game_time), _format_time(run_duration)]
	kill_label.text = "击败 %d" % GameManager.kill_count
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
	get_tree().paused = false
	get_tree().reload_current_scene()

func _start_next_level() -> void:
	var next_level := GameManager.get_next_level()
	if next_level == null:
		_return_to_level_select()
		return
	get_tree().paused = false
	GameManager.select_level(next_level)
	get_tree().reload_current_scene()

func _return_to_level_select() -> void:
	get_tree().paused = false
	InputAdapter.clear_virtual_move()
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _return_home() -> void:
	get_tree().paused = false
	InputAdapter.clear_virtual_move()
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
	var active_orbs: int = $GameWorld/ExperiencePool.get_active_orb_count()
	var enemy_bullets: int = $GameWorld/EnemyProjectilePool.get_active_count()
	print("STRESS_TEST enemies=%d bullets=%d enemy_bullets=%d orbs=%d pool_limit=%d" % [enemy_spawner.get_active_enemy_count(), active_bullets, enemy_bullets, active_orbs, enemy_spawner.active_enemy_limit])
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
