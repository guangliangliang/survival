extends Control

const ICON_BACK := preload("res://assets/images/ui/icons/back.svg")
const ICON_START := preload("res://assets/images/ui/icons/start.svg")
const BUTTON_TEXT_COLOR := Color("f4e2b2")
const MAP_TEXTURES := {
	&"frontier_desert": preload("res://assets/images/maps/map_frontier_desert_plain.png"),
	&"frontier_grassland": preload("res://assets/images/maps/map_frontier_grassland_plain.png"),
	&"frontier_red_earth": preload("res://assets/images/maps/map_frontier_red_earth_plain.png")
}

@onready var back_button: Button = $Margin/VBox/Header/BackButton
@onready var start_button: Button = $Margin/VBox/Header/StartButton
@onready var title_label: Label = $Margin/VBox/Header/TitleBox/TitleLabel
@onready var subtitle_label: Label = $Margin/VBox/Header/TitleBox/SubtitleLabel
@onready var content: HBoxContainer = $Margin/VBox/Content

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	back_button.pressed.connect(_return_to_level_select)
	start_button.pressed.connect(_start_game)
	_set_centered_button_content(back_button, ICON_BACK, 24, 8, 18)
	_set_centered_button_content(start_button, ICON_START, 24, 8, 18)
	_style_button(back_button, Color("3b332d"), Color("8e8069"))
	_style_button(start_button, Color("6f3d25"), Color("d9b56b"))
	_build_briefing()

func _build_briefing() -> void:
	for child in content.get_children():
		child.queue_free()
	var level_data: Resource = GameManager.selected_level
	if level_data == null and not GameManager.level_catalog.is_empty():
		level_data = GameManager.level_catalog[0]
		GameManager.select_level(level_data)
	var character_data: Resource = GameManager.selected_character
	if level_data == null:
		return
	title_label.text = level_data.title
	subtitle_label.text = "地图、主角与敌人情报"
	content.add_child(_create_character_panel(character_data))
	content.add_child(_create_map_panel(level_data))
	content.add_child(_create_enemy_panel(level_data))

func _create_character_panel(character_data: Resource) -> Control:
	var panel := _create_panel(Vector2(278, 0), Color("7e6846"))
	var box := _create_panel_box(panel, 14)
	_add_section_title(box, "主角")

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(0, 292)
	portrait_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_frame.add_theme_stylebox_override("panel", _inner_box(Color(0.03, 0.038, 0.032, 0.9), Color("4f5d45")))
	box.add_child(portrait_frame)

	var portrait_area := Control.new()
	portrait_area.clip_contents = true
	portrait_area.custom_minimum_size = Vector2(0, 292)
	portrait_frame.add_child(portrait_area)
	if character_data != null:
		_add_full_rect_texture(portrait_area, _make_sprite_frame(character_data.body_texture), 18)
		_add_full_rect_texture(portrait_area, character_data.rifle_texture, 18)

	var name_label := Label.new()
	name_label.text = character_data.display_name if character_data != null else "未选择"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color("fff0c6"))
	box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = character_data.description if character_data != null else ""
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color("b8c9ad"))
	box.add_child(desc_label)
	return panel

func _create_map_panel(level_data: Resource) -> Control:
	var panel := _create_panel(Vector2(520, 0), level_data.accent_color.lightened(0.1))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := _create_panel_box(panel, 14)
	_add_section_title(box, "地图")

	var map_frame := PanelContainer.new()
	map_frame.custom_minimum_size = Vector2(0, 392)
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.add_theme_stylebox_override("panel", _inner_box(Color(0.025, 0.03, 0.026, 0.92), level_data.accent_color.lightened(0.06)))
	box.add_child(map_frame)

	var map_image := TextureRect.new()
	map_image.texture = _get_map_texture(level_data)
	map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_frame.add_child(map_image)

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	box.add_child(info_row)
	info_row.add_child(_create_info_chip("预计时间", level_data.formatted_duration(), level_data.accent_color))
	info_row.add_child(_create_info_chip("首领登场", _format_time(level_data.boss_spawn_time), level_data.accent_color))

	var desc_label := Label.new()
	desc_label.text = level_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color("d8d0b0"))
	box.add_child(desc_label)
	return panel

func _create_enemy_panel(level_data: Resource) -> Control:
	var panel := _create_panel(Vector2(336, 0), Color("9d6b44"))
	var box := _create_panel_box(panel, 12)
	_add_section_title(box, "怪物列表")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for enemy_data in level_data.enemy_catalog:
		list.add_child(_create_enemy_row(enemy_data, false, level_data.accent_color, level_data.boss_spawn_time))
	if level_data.boss_data != null:
		list.add_child(_create_enemy_row(level_data.boss_data, true, level_data.accent_color, level_data.boss_spawn_time))
	return panel

func _create_enemy_row(enemy_data: Resource, is_boss: bool, accent_color: Color, boss_spawn_time: float) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 88 if not is_boss else 98)
	row_panel.add_theme_stylebox_override("panel", _enemy_row_box(is_boss, accent_color))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(64, 64)
	icon_frame.add_theme_stylebox_override("panel", _inner_box(Color(0.02, 0.024, 0.022, 0.82), enemy_data.color.lightened(0.12)))
	row.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.texture = _get_enemy_texture(enemy_data)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_frame.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	text_box.add_child(name_row)

	var name_label := Label.new()
	name_label.text = enemy_data.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("fff0c6"))
	name_row.add_child(name_label)

	if is_boss:
		var badge := Label.new()
		badge.text = "首领"
		badge.add_theme_font_size_override("font_size", 14)
		badge.add_theme_color_override("font_color", Color("ffdf7a"))
		name_row.add_child(badge)

	var stat_label := Label.new()
	stat_label.text = "生命 %d  攻击 %d" % [int(enemy_data.max_health), int(enemy_data.damage)]
	stat_label.add_theme_font_size_override("font_size", 13)
	stat_label.add_theme_color_override("font_color", Color("c8d1bd"))
	text_box.add_child(stat_label)

	var trait_label := Label.new()
	trait_label.text = _get_enemy_trait_text(enemy_data, is_boss, boss_spawn_time)
	trait_label.add_theme_font_size_override("font_size", 13)
	trait_label.add_theme_color_override("font_color", Color("aeb89e"))
	text_box.add_child(trait_label)
	return row_panel

func _get_enemy_trait_text(enemy_data: Resource, is_boss: bool, boss_spawn_time: float) -> String:
	if is_boss:
		return "最终威胁  登场 %s" % _format_time(boss_spawn_time)
	if enemy_data.ranged:
		return "远程单位  经验 %d" % enemy_data.exp_reward
	if enemy_data.elite:
		return "精英单位  经验 %d" % enemy_data.exp_reward
	return "近战单位  经验 %d" % enemy_data.exp_reward

func _create_panel(min_size: Vector2, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_box(border_color))
	return panel

func _create_panel_box(panel: PanelContainer, separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)
	return box

func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", Color("e8d99a"))
	parent.add_child(label)

func _add_full_rect_texture(parent: Control, texture: Texture2D, inset: int) -> void:
	if texture == null:
		return
	var image := TextureRect.new()
	image.texture = texture
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = inset
	image.offset_top = inset
	image.offset_right = -inset
	image.offset_bottom = -inset
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func _create_info_chip(label_text: String, value_text: String, accent_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _inner_box(accent_color.darkened(0.45), accent_color.lightened(0.08)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("b8c9ad"))
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color("fff0c6"))
	box.add_child(value)
	return panel

func _get_map_texture(level_data: Resource) -> Texture2D:
	var texture: Texture2D = MAP_TEXTURES.get(level_data.map_variant, MAP_TEXTURES[&"frontier_desert"])
	return texture

func _make_sprite_frame(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, 128, 128)
	return atlas

func _get_enemy_texture(enemy_data: Resource) -> Texture2D:
	if enemy_data.texture != null:
		return enemy_data.texture
	if enemy_data.walk_texture != null:
		return _make_sprite_frame(enemy_data.walk_texture)
	return null

func _format_time(value: float) -> String:
	var total := maxi(0, int(value))
	return "%02d:%02d" % [total / 60, total % 60]

func _start_game() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _return_to_level_select() -> void:
	AudioManager.play_ui_by_key(&"back")
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.08), border.lightened(0.12)))
	button.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_constant_override("h_separation", 10)

func _set_centered_button_content(button: Button, texture: Texture2D, icon_size: int, gap: int, font_size: int) -> void:
	var label_text := button.text
	button.text = ""
	button.icon = null

	var existing := button.get_node_or_null("CenteredContent")
	if existing != null:
		existing.queue_free()

	var content_box := HBoxContainer.new()
	content_box.name = "CenteredContent"
	content_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_theme_constant_override("separation", gap)
	button.add_child(content_box)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", font_size)
	content_box.add_child(label)

func _panel_box(border_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.07, 0.052, 0.94)
	box.border_color = border_color
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(16)
	box.shadow_color = Color(0, 0, 0, 0.46)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 4)
	return box

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.32)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	return box

func _inner_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(8)
	return box

func _enemy_row_box(is_boss: bool, accent_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.10, 0.058, 0.036, 0.94) if is_boss else Color(0.04, 0.05, 0.043, 0.9)
	box.border_color = accent_color.lightened(0.18) if is_boss else Color("5f6a52")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(9)
	return box
