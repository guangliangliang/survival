extends Node2D

const EnemyScene := preload("res://scenes/game/Enemy.tscn")

const BOSS_DATA: Array[Resource] = [
	preload("res://resources/enemies/alpha_wolf.tres"),
	preload("res://resources/enemies/forest_beast.tres"),
	preload("res://resources/enemies/boss.tres"),
]
const BOSS_LAYER_COLORS: Array[Color] = [
	Color("d43a2b"),
	Color("9b4fd0"),
	Color("f1bd32"),
]
const BOSS_BAR_EMPTY_FILL := Color(0.106, 0.09, 0.078, 1.0)
const BOSS_BAR_EMPTY_BORDER := Color(0.373, 0.322, 0.251, 1.0)

@onready var game_world: Node2D = $GameWorld
@onready var boss_bar: Control = $CanvasLayer/GameUI/BossBar
@onready var boss_name_label: Label = $CanvasLayer/GameUI/BossBar/Panel/VBox/NameLabel
@onready var boss_progress_bar: ProgressBar = $CanvasLayer/GameUI/BossBar/Panel/VBox/ProgressBar
@onready var status_label: Label = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/StatusLabel
@onready var boss_row: HBoxContainer = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/BossRow
@onready var damage_10_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/DamageRow/Damage10Button
@onready var damage_100_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/DamageRow/Damage100Button
@onready var damage_500_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/DamageRow/Damage500Button
@onready var damage_1000_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/DamageRow/Damage1000Button
@onready var kill_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/ActionRow/KillButton
@onready var reset_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/ActionRow/ResetButton
@onready var respawn_button: Button = $CanvasLayer/GameUI/ControlPanel/Margin/VBox/ActionRow/RespawnButton

var current_boss: CharacterBody2D = null
var boss_health_component: Node = null
var boss_total_layers: int = 1
var boss_layer_per: float = 0.0
var current_boss_index: int = 0
var boss_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	GameManager.start_run()
	_build_boss_buttons()
	damage_10_button.pressed.connect(_apply_damage.bind(10.0))
	damage_100_button.pressed.connect(_apply_damage.bind(100.0))
	damage_500_button.pressed.connect(_apply_damage.bind(500.0))
	damage_1000_button.pressed.connect(_apply_damage.bind(1000.0))
	kill_button.pressed.connect(_apply_damage.bind(999999.0))
	reset_button.pressed.connect(_reset_current_boss)
	respawn_button.pressed.connect(func(): _spawn_boss(current_boss_index))
	_spawn_boss(0)

func _process(_delta: float) -> void:
	_update_boss_bar()
	_update_status_label()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _build_boss_buttons() -> void:
	for i in range(BOSS_DATA.size()):
		var data: Resource = BOSS_DATA[i]
		var btn := Button.new()
		btn.text = data.display_name
		btn.custom_minimum_size = Vector2(110, 40)
		btn.pressed.connect(func(): _on_boss_button_pressed(i))
		boss_row.add_child(btn)
		boss_buttons.append(btn)

func _on_boss_button_pressed(index: int) -> void:
	current_boss_index = index
	_spawn_boss(index)

func _spawn_boss(index: int) -> void:
	_hide_boss_bar()
	if is_instance_valid(current_boss):
		current_boss.queue_free()
		current_boss = null
	var data: Resource = BOSS_DATA[index]
	current_boss = EnemyScene.instantiate() as CharacterBody2D
	current_boss.name = "%s_TestBoss" % data.enemy_id
	game_world.add_child(current_boss)
	current_boss.reset_for_spawn(data, null, Vector2(0, 0))

func _reset_current_boss() -> void:
	if not is_instance_valid(current_boss):
		return
	var hc: Node = current_boss.get_node_or_null("HealthComponent")
	if hc != null:
		hc.reset()

func _apply_damage(amount: float) -> void:
	if not is_instance_valid(current_boss) or not current_boss.is_alive:
		return
	if current_boss.has_method("receive_hit"):
		current_boss.receive_hit(amount, Vector2.RIGHT)

func _update_status_label() -> void:
	if not is_instance_valid(current_boss):
		status_label.text = "生命值: -- / --"
		return
	var hc: Node = current_boss.get_node_or_null("HealthComponent")
	if hc == null:
		status_label.text = "生命值: -- / --"
		return
	var alive_text := "存活" if current_boss.is_alive else "已倒下"
	status_label.text = "生命值: %.0f / %.0f  |  %s" % [hc.current_health, hc.max_health, alive_text]

# ---- Boss 血条逻辑（与 Game.gd 保持一致） ----

func _update_boss_bar() -> void:
	if is_instance_valid(current_boss) and current_boss.is_alive:
		if boss_health_component == null:
			_bind_boss(current_boss)
		return
	if boss_health_component != null:
		_hide_boss_bar()

func _bind_boss(boss: CharacterBody2D) -> void:
	current_boss = boss
	boss_health_component = boss.get_node_or_null("HealthComponent")
	if boss_health_component == null:
		return
	boss_total_layers = max(boss.enemy_data.boss_health_bars, 1)
	boss_layer_per = boss_health_component.max_health / float(boss_total_layers)
	if not boss_health_component.health_changed.is_connected(_on_boss_health_changed):
		boss_health_component.health_changed.connect(_on_boss_health_changed)
	boss_bar.visible = true
	_on_boss_health_changed(boss_health_component.current_health, boss_health_component.max_health)

func _on_boss_health_changed(current: float, max_hp: float) -> void:
	var per: float = max_hp / float(boss_total_layers)
	var clamped: float = max(current, 0.0)
	var layers_left: int = clamp(int(ceil(clamped / per)), 1, boss_total_layers)
	var in_layer: float = clamped - per * float(layers_left - 1)
	boss_progress_bar.max_value = per
	boss_progress_bar.value = in_layer
	_apply_boss_layer_color(layers_left)
	if is_instance_valid(current_boss):
		boss_name_label.text = "%s  ×%d" % [current_boss.enemy_data.display_name, layers_left]

func _apply_boss_layer_color(layers_left: int) -> void:
	var fill: Color = _get_boss_layer_color(layers_left)
	boss_progress_bar.add_theme_stylebox_override("fill", _bar_box(fill, fill.lightened(0.3), 2))
	if layers_left > 1:
		var next_fill: Color = _get_boss_layer_color(layers_left - 1)
		boss_progress_bar.add_theme_stylebox_override("background", _bar_box(next_fill, next_fill.lightened(0.2), 2))
	else:
		boss_progress_bar.add_theme_stylebox_override("background", _bar_box(BOSS_BAR_EMPTY_FILL, BOSS_BAR_EMPTY_BORDER, 2))

func _get_boss_layer_color(layers_left: int) -> Color:
	var index: int = clampi(layers_left - 1, 0, BOSS_LAYER_COLORS.size() - 1)
	return BOSS_LAYER_COLORS[index]

func _bar_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _hide_boss_bar() -> void:
	if boss_health_component != null and is_instance_valid(boss_health_component):
		if boss_health_component.health_changed.is_connected(_on_boss_health_changed):
			boss_health_component.health_changed.disconnect(_on_boss_health_changed)
	boss_health_component = null
	if boss_bar != null:
		boss_bar.visible = false

# 供 Enemy.gd 的 shake_camera 调用（Enemy 攻击时会调 game_controller）
func shake_camera(_strength: float) -> void:
	pass
