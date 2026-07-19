extends Node2D

const EnemyScene := preload("res://scenes/game/Enemy.tscn")
const PreviewEnemyData := preload("res://resources/enemies/wolf.tres")

@onready var game_world: Node2D = $GameWorld
@onready var experience_pool: Node2D = $GameWorld/ExperiencePool
@onready var visual_effects_pool: Node2D = $GameWorld/VisualEffectsPool

var active_gem: Area2D
var active_enemy: CharacterBody2D
var load_button: Button
var remove_button: Button
var status_label: Label
var load_version: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	GameManager.player = null
	_build_ui()
	_update_status()

func _draw() -> void:
	draw_rect(Rect2(-640, -360, 1280, 720), Color("1f2f2d"))
	draw_rect(Rect2(-640, 84, 1280, 90), Color("5e5844"))
	draw_circle(Vector2.ZERO, 74.0, Color(0.0, 0.0, 0.0, 0.16))
	draw_circle(Vector2.ZERO, 45.0, Color("37564e"))

func _on_load_pressed() -> void:
	if is_instance_valid(active_gem):
		return
	_clear_preview()
	load_version += 1
	active_enemy = EnemyScene.instantiate() as CharacterBody2D
	active_enemy.name = "PreviewEnemy"
	game_world.add_child(active_enemy)
	var enemy_data := PreviewEnemyData.duplicate(true)
	enemy_data.visual_scale_multiplier *= 1.25
	active_enemy.call("reset_for_spawn", enemy_data, null, Vector2.ZERO)
	_update_status("怪物已加载，即将播放死亡特效。")
	get_tree().create_timer(0.35).timeout.connect(_kill_active_enemy.bind(load_version))

func _on_remove_pressed() -> void:
	load_version += 1
	_clear_preview()
	_update_status()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 24.0
	panel.offset_top = 20.0
	panel.offset_right = 394.0
	panel.offset_bottom = 184.0
	$CanvasLayer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "经验宝石测试"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("d7c89b"))
	box.add_child(status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)

	load_button = _make_button("加载")
	load_button.pressed.connect(_on_load_pressed)
	buttons.add_child(load_button)

	remove_button = _make_button("移除")
	remove_button.pressed.connect(_on_remove_pressed)
	buttons.add_child(remove_button)

	_apply_panel_style(panel)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 44)
	return button

func _apply_panel_style(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.052, 0.046, 0.94)
	box.border_color = Color("8d7754")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", box)

func _update_status(message: String = "") -> void:
	active_gem = _get_active_gem()
	var has_enemy := is_instance_valid(active_enemy)
	var has_gem := is_instance_valid(active_gem)
	if message.is_empty():
		message = "点击加载：展示怪物死亡特效，并生成经验宝石。" if not has_enemy and not has_gem else "死亡特效已播放，经验宝石已生成。"
	status_label.text = message
	load_button.disabled = has_enemy or has_gem
	remove_button.disabled = not has_enemy and not has_gem

func _kill_active_enemy(version: int) -> void:
	if version != load_version or not is_instance_valid(active_enemy):
		return
	var enemy := active_enemy
	enemy.call("receive_hit", PreviewEnemyData.max_health + 999.0, Vector2.RIGHT)
	active_enemy = null
	enemy.queue_free()
	active_gem = _get_active_gem()
	_update_status("怪物死亡特效已播放，经验宝石已生成。")

func _clear_preview() -> void:
	if is_instance_valid(active_enemy):
		active_enemy.queue_free()
	active_enemy = null
	active_gem = null
	for child in experience_pool.get_children():
		if child.has_method("deactivate"):
			child.call("deactivate")
	for child in visual_effects_pool.get_children():
		if child is Sprite2D:
			child.visible = false

func _get_active_gem() -> Area2D:
	for child in experience_pool.get_children():
		if child is Area2D and bool(child.get("active")):
			return child
	return null
