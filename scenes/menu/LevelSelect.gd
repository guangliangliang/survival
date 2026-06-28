extends Control

const LevelPreviewControl = preload("res://scripts/ui/LevelPreview.gd")
const ENEMY_ATTACK_TEST_SCENE := "res://scenes/debug/EnemyAttackTest.tscn"

@onready var cards: HBoxContainer = $Margin/VBox/Cards
@onready var back_button: Button = $Margin/VBox/Header/BackButton
@onready var debug_button: Button = $Margin/VBox/Header/DebugButton

func _ready() -> void:
	back_button.pressed.connect(_return_home)
	debug_button.pressed.connect(_start_enemy_attack_test)
	_style_button(back_button, Color("3b332d"), Color("8e8069"))
	_style_button(debug_button, Color("3b332d"), Color("8e8069"))
	_build_level_cards()

func _build_level_cards() -> void:
	for child in cards.get_children():
		child.queue_free()
	for index in GameManager.level_catalog.size():
		cards.add_child(_create_level_card(GameManager.level_catalog[index], index))

func _create_level_card(level_data: Resource, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 430)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.07, 0.052, 0.92)
	panel_style.border_color = level_data.accent_color.lightened(0.05)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(18.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", panel_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var preview := LevelPreviewControl.new()
	preview.custom_minimum_size = Vector2(0, 155)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.configure(level_data)
	box.add_child(preview)

	var number := Label.new()
	number.text = "关卡 %d" % (index + 1)
	number.add_theme_font_size_override("font_size", 17)
	number.add_theme_color_override("font_color", Color("e8d99a"))
	box.add_child(number)

	var title := Label.new()
	title.text = level_data.title
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var duration := Label.new()
	duration.text = "预计时间  %s" % level_data.formatted_duration()
	duration.add_theme_color_override("font_color", Color("b8c9ad"))
	box.add_child(duration)

	var description := Label.new()
	description.text = level_data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 17)
	box.add_child(description)

	var play := Button.new()
	play.text = "进入关卡"
	play.custom_minimum_size = Vector2(0, 58)
	_style_button(play, level_data.accent_color.darkened(0.32), level_data.accent_color.lightened(0.12))
	play.pressed.connect(_start_level.bind(level_data))
	box.add_child(play)
	return panel

func _start_level(level_data: Resource) -> void:
	GameManager.select_level(level_data)
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _return_home() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _start_enemy_attack_test() -> void:
	get_tree().change_scene_to_file(ENEMY_ATTACK_TEST_SCENE)

func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_color_override("font_color", Color("f4e2b2"))
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", 18)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	return box
