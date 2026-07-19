extends Control

const ICON_START := preload("res://assets/images/ui/icons/start.svg")
const BUTTON_TEXT_COLOR := Color("f4e2b2")

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle: Label = $Subtitle

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	start_button.pressed.connect(_on_start_button_pressed)
	_apply_style()

func _on_start_button_pressed() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _apply_style() -> void:
	title_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.035, 0.018, 0.95))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	_set_centered_button_content(start_button, ICON_START, 28, 12, 24)
	_style_button(start_button, Color("8a4b27"), Color("d9b56b"))

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
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	content.add_child(label)

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
	box.set_content_margin_all(12)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box
