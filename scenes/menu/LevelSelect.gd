extends Control

const LevelPreviewControl = preload("res://scripts/ui/LevelPreview.gd")
const ICON_BACK := preload("res://assets/images/ui/icons/back.svg")
const ICON_START := preload("res://assets/images/ui/icons/start.svg")
const BUTTON_TEXT_COLOR := Color("f4e2b2")

@onready var layout_box: VBoxContainer = $Margin/VBox
@onready var cards: HBoxContainer = $Margin/VBox/Cards
@onready var back_button: Button = $Margin/VBox/Header/BackButton

var character_buttons: Dictionary = {}

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	back_button.pressed.connect(_return_home)
	_set_centered_button_content(back_button, ICON_BACK, 30, 10, 24)  # 增大图标和字体
	_style_button(back_button, Color("3b332d"), Color("8e8069"))
	_build_character_selector()
	_build_level_cards()

func _build_character_selector() -> void:
	character_buttons.clear()
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.052, 0.043, 0.9)
	panel_style.border_color = Color("7e6846")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(18.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", panel_style)
	layout_box.add_child(panel)
	layout_box.move_child(panel, cards.get_index())

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "选择主角"
	title.add_theme_font_size_override("font_size", 26)  # 增大字体
	title.add_theme_color_override("font_color", Color("e8d99a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	for character_data in GameManager.character_catalog:
		var button := _create_character_button(character_data)
		row.add_child(button)
		character_buttons[character_data.character_id] = button
	_update_character_buttons()

func _create_character_button(character_data: Resource) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300, 96)  # 增加按钮高度以适应文本
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.text = ""
	button.pressed.connect(_select_character.bind(character_data))

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_top = 10
	row.offset_right = -14
	row.offset_bottom = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(row)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(72, 72)  # 增大图标
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.texture = _make_character_preview(character_data.body_texture)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(preview)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_box.add_theme_constant_override("separation", 4)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = character_data.display_name
	name_label.add_theme_font_size_override("font_size", 24)  # 增大字体
	name_label.add_theme_color_override("font_color", Color("f4e2b2"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = character_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)  # 稍微调整字体大小以适应
	desc_label.add_theme_color_override("font_color", Color("b8c9ad"))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(desc_label)
	return button

func _make_character_preview(texture: Texture2D) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, 128, 128)
	return atlas

func _select_character(character_data: Resource) -> void:
	AudioManager.play_ui_by_key(&"button_click")
	GameManager.select_character(character_data)
	_update_character_buttons()

func _update_character_buttons() -> void:
	for character_data in GameManager.character_catalog:
		var button := character_buttons.get(character_data.character_id) as Button
		if button == null:
			continue
		var selected: bool = GameManager.selected_character != null and GameManager.selected_character.character_id == character_data.character_id
		button.button_pressed = selected
		_style_character_button(button, selected)

func _build_level_cards() -> void:
	for child in cards.get_children():
		child.queue_free()
	for index in GameManager.level_catalog.size():
		cards.add_child(_create_level_card(GameManager.level_catalog[index], index))

func _create_level_card(level_data: Resource, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 360)
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
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var preview := LevelPreviewControl.new()
	preview.custom_minimum_size = Vector2(0, 120)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.configure(level_data)
	box.add_child(preview)

	var number := Label.new()
	number.text = "关卡 %d" % (index + 1)
	number.add_theme_font_size_override("font_size", 22)  # 增大字体
	number.add_theme_color_override("font_color", Color("e8d99a"))
	box.add_child(number)

	var title := Label.new()
	title.text = level_data.title
	title.add_theme_font_size_override("font_size", 34)  # 增大字体
	box.add_child(title)

	var duration := Label.new()
	duration.text = "预计时间  %s" % level_data.formatted_duration()
	duration.add_theme_color_override("font_color", Color("b8c9ad"))
	duration.add_theme_font_size_override("font_size", 20)  # 增大字体
	box.add_child(duration)

	var description := Label.new()
	description.text = level_data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 20)  # 增大字体
	box.add_child(description)

	var play := Button.new()
	play.text = "查看地图敌情"
	play.custom_minimum_size = Vector2(0, 58)
	_set_centered_button_content(play, ICON_START, 32, 12, 24)  # 增大图标和字体
	_style_button(play, level_data.accent_color.darkened(0.32), level_data.accent_color.lightened(0.12))
	play.pressed.connect(_start_level.bind(level_data))
	box.add_child(play)
	return panel

func _start_level(level_data: Resource) -> void:
	AudioManager.play_ui_by_key(&"button_click")
	GameManager.select_level(level_data)
	get_tree().change_scene_to_file("res://scenes/menu/LevelBriefing.tscn")

func _return_home() -> void:
	AudioManager.play_ui_by_key(&"back")
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_color_override("font_color", Color("f4e2b2"))
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_constant_override("h_separation", 10)

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

func _style_character_button(button: Button, selected: bool) -> void:
	var fill := Color("594728") if selected else Color("3b332d")
	var border := Color("d9b56b") if selected else Color("8e8069")
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.08), border.lightened(0.12)))

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	# 再增加左右边距
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_color = Color(0, 0, 0, 0.32)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	return box
