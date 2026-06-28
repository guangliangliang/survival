extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle: Label = $Subtitle

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.visible = not OS.has_feature("web")
	_apply_style()

func _on_start_button_pressed() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _on_quit_button_pressed() -> void:
	AudioManager.play_ui_by_key(&"back")
	get_tree().quit()

func _apply_style() -> void:
	title_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.035, 0.018, 0.95))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	_style_button(start_button, Color("8a4b27"), Color("d9b56b"))
	_style_button(quit_button, Color("3b332d"), Color("8e8069"))

func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.08), border.lightened(0.12)))
	button.add_theme_color_override("font_color", Color("f4e2b2"))
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", 24)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box
