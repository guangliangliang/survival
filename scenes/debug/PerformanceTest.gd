extends Control

const LevelPreviewControl = preload("res://scripts/ui/LevelPreview.gd")
const ICON_BACK := preload("res://assets/images/ui/icons/back.svg")
const ICON_START := preload("res://assets/images/ui/icons/start.svg")
const ICON_PERFORMANCE := preload("res://assets/images/ui/icons/time.svg")
const BUTTON_TEXT_COLOR := Color("f4e2b2")
const TEXT_MUTED := Color("b8c9ad")
const TEXT_BODY := Color("d8d0b0")
const PANEL_FILL := Color(0.055, 0.07, 0.052, 0.94)
const CARD_FILL := Color(0.04, 0.05, 0.043, 0.92)

@onready var back_button: Button = $Margin/VBox/Header/BackButton
@onready var start_button: Button = $Margin/VBox/Header/StartButton
@onready var title_label: Label = $Margin/VBox/Header/TitleBox/TitleLabel
@onready var subtitle_label: Label = $Margin/VBox/Header/TitleBox/SubtitleLabel
@onready var content: HBoxContainer = $Margin/VBox/Content

var map_select: OptionButton
var count_select: OptionButton
var map_preview
var level_summary_label: Label
var enemy_summary_label: Label
var count_summary_label: Label
var level_options: Array[Resource] = []
var count_options: Array[int] = []

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	back_button.pressed.connect(_return_home)
	start_button.pressed.connect(_start_performance_test)
	_set_centered_button_content(back_button, ICON_BACK, 30, 10, 24)
	_set_centered_button_content(start_button, ICON_START, 30, 10, 24)
	_style_button(back_button, Color("3b332d"), Color("8e8069"))
	_style_button(start_button, Color("6f3d25"), Color("d9b56b"))
	_apply_title_style()
	_build_test_interface()
	_populate_maps()
	_populate_counts()
	_update_test_summary()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_home()
		get_viewport().set_input_as_handled()

func _apply_title_style() -> void:
	title_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.035, 0.018, 0.95))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	subtitle_label.text = "独立测试场"

func _build_test_interface() -> void:
	for child in content.get_children():
		child.queue_free()
	content.add_child(_create_config_panel())
	content.add_child(_create_preview_panel())
	content.add_child(_create_summary_panel())

func _create_config_panel() -> Control:
	var panel := _create_panel(Vector2(360, 0), Color("c7b36b"))
	var box := _create_panel_box(panel, 16)
	_add_section_title(box, "测试参数")

	var map_row := _create_option_row("测试地图")
	map_select = map_row["option"] as OptionButton
	map_select.item_selected.connect(_on_map_selected)
	box.add_child(map_row["row"] as Control)

	var count_row := _create_option_row("普通怪数量")
	count_select = count_row["option"] as OptionButton
	count_select.item_selected.connect(_on_count_selected)
	box.add_child(count_row["row"] as Control)

	var detail := _create_label("普通怪将按全敌人目录混合生成，所选地图的 Boss 会同时在场。", 17, TEXT_MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail)

	box.add_child(_create_rule_chip("模式", "主角无敌，保留攻击"))
	box.add_child(_create_rule_chip("刷怪", "维持目标数量，持续补齐"))
	box.add_child(_create_rule_chip("指标", "游戏内显示活跃数与 FPS"))
	return panel

func _create_preview_panel() -> Control:
	var panel := _create_panel(Vector2(500, 0), Color("7e6846"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := _create_panel_box(panel, 14)
	_add_section_title(box, "地图预览")

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(0, 340)
	preview_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_frame.add_theme_stylebox_override("panel", _inner_box(Color(0.025, 0.03, 0.026, 0.92), Color("5f6a52")))
	box.add_child(preview_frame)

	map_preview = LevelPreviewControl.new()
	map_preview.custom_minimum_size = Vector2(0, 320)
	map_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(map_preview)

	level_summary_label = _create_label("", 20, TEXT_BODY)
	level_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(level_summary_label)
	return panel

func _create_summary_panel() -> Control:
	var panel := _create_panel(Vector2(300, 0), Color("9d6b44"))
	var box := _create_panel_box(panel, 14)
	_add_section_title(box, "测试摘要")

	count_summary_label = _create_label("", 28, Color("fff0c6"))
	count_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(count_summary_label)

	enemy_summary_label = _create_label("", 17, TEXT_MUTED)
	enemy_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(enemy_summary_label)

	box.add_child(_create_rule_chip("音频", "沿用当前音量设置"))
	box.add_child(_create_rule_chip("退出", "返回菜单会清除测试状态"))
	return panel

func _create_option_row(label_text: String) -> Dictionary:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := _create_label(label_text, 20, Color("fff0c6"))
	row.add_child(label)

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, 54)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_theme_font_size_override("font_size", 21)
	option.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	_style_button(option, Color("3b332d"), Color("8e8069"), 21)
	row.add_child(option)
	return {"row": row, "option": option}

func _populate_maps() -> void:
	level_options.clear()
	map_select.clear()
	var selected_index := 0
	for index in GameManager.level_catalog.size():
		var level_data: Resource = GameManager.level_catalog[index]
		level_options.append(level_data)
		map_select.add_item(level_data.title, index)
		if _is_selected_level(level_data):
			selected_index = index
	if not level_options.is_empty():
		map_select.select(selected_index)

func _populate_counts() -> void:
	count_options = GameManager.get_performance_test_count_presets()
	count_select.clear()
	var default_count := GameManager.performance_test_target_count if GameManager.performance_test_target_count > 0 else GameManager.get_default_performance_test_count()
	var selected_index := 0
	var selected_delta := 2147483647
	for index in count_options.size():
		var count := count_options[index]
		count_select.add_item("%d 只" % count, index)
		var delta := absi(count - default_count)
		if delta < selected_delta:
			selected_delta = delta
			selected_index = index
	if not count_options.is_empty():
		count_select.select(selected_index)

func _is_selected_level(level_data: Resource) -> bool:
	if GameManager.performance_test_level != null:
		return level_data.level_id == GameManager.performance_test_level.level_id
	return GameManager.selected_level != null and level_data.level_id == GameManager.selected_level.level_id

func _on_map_selected(_index: int) -> void:
	AudioManager.play_ui_by_key(&"button_click")
	_update_test_summary()

func _on_count_selected(_index: int) -> void:
	AudioManager.play_ui_by_key(&"button_click")
	_update_test_summary()

func _update_test_summary() -> void:
	var level_data: Resource = _get_selected_level()
	var target_count: int = _get_selected_count()
	start_button.disabled = level_data == null or target_count <= 0
	if level_data == null:
		level_summary_label.text = "暂无可用测试地图。"
		enemy_summary_label.text = ""
		count_summary_label.text = "0 只"
		return
	if map_preview != null:
		map_preview.configure(level_data)
	level_summary_label.text = "%s\n%s" % [level_data.title, level_data.description]
	count_summary_label.text = "%d 只普通怪" % target_count
	var boss_text: String = level_data.boss_data.display_name if level_data.boss_data != null else "无 Boss"
	enemy_summary_label.text = "Boss：%s\n预计时长：%s\n敌人种类：%d" % [
		boss_text,
		level_data.formatted_duration(),
		GameManager.get_performance_test_enemy_catalog().size()
	]

func _get_selected_level() -> Resource:
	if level_options.is_empty():
		return null
	var index := clampi(map_select.selected, 0, level_options.size() - 1)
	return level_options[index]

func _get_selected_count() -> int:
	if count_options.is_empty():
		return 0
	var index := clampi(count_select.selected, 0, count_options.size() - 1)
	return count_options[index]

func _start_performance_test() -> void:
	var level_data: Resource = _get_selected_level()
	var target_count: int = _get_selected_count()
	if level_data == null or target_count <= 0:
		AudioManager.play_ui_by_key(&"invalid")
		return
	AudioManager.play_ui_by_key(&"button_click")
	GameManager.start_performance_test(level_data, target_count)
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _return_home() -> void:
	AudioManager.play_ui_by_key(&"back")
	GameManager.clear_performance_test()
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _create_panel(min_size: Vector2, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_box(PANEL_FILL, border_color, 16, 3))
	return panel

func _create_panel_box(panel: PanelContainer, separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)
	return box

func _create_rule_chip(label_text: String, value_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _inner_box(CARD_FILL, Color("5f6a52")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var label := _create_label(label_text, 16, Color("e8d99a"))
	label.custom_minimum_size = Vector2(58, 0)
	row.add_child(label)

	var value := _create_label(value_text, 16, TEXT_MUTED)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	return panel

func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.texture = ICON_PERFORMANCE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label := _create_label(text, 27, Color("e8d99a"))
	row.add_child(label)

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style_button(button: Button, fill: Color, border: Color, font_size: int = 24) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.08), border.lightened(0.12)))
	button.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", font_size)

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

func _panel_box(fill: Color, border: Color, margin: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(margin)
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
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 10
	box.content_margin_bottom = 10
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
