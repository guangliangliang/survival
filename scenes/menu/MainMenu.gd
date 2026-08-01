extends Control

const ICON_START := preload("res://assets/images/ui/icons/start.svg")
const ICON_BACK := preload("res://assets/images/ui/icons/back.svg")
const ICON_CODEX := preload("res://assets/images/ui/icons/level.svg")
const ICON_UPGRADE := preload("res://assets/images/ui/icons/skill.svg")
const ICON_SETTINGS := preload("res://assets/images/ui/icons/settings.svg")
const ICON_DAMAGE := preload("res://assets/images/ui/icons/damage.svg")
const ICON_FIRE_RATE := preload("res://assets/images/ui/icons/fire_rate.svg")
const ICON_RANGE := preload("res://assets/images/ui/icons/range.svg")
const ICON_PIERCE := preload("res://assets/images/ui/icons/pierce.svg")
const ICON_FLYWHEEL := preload("res://assets/images/weapons/weapon_orbit_flywheel.png")
const ICON_DRONE := preload("res://assets/images/weapons/weapon_combat_drone.png")
const ICON_HEALTH := preload("res://assets/images/ui/icons/health.svg")
const ICON_PROJECTILE := preload("res://assets/images/ui/icons/projectiles.svg")
const ICON_SCATTER := preload("res://assets/images/ui/icon_laser_sweep.svg")
const ICON_ARROW := preload("res://assets/images/ui/icons/arrow.svg")
const ICON_HEAL := preload("res://assets/images/ui/icons/heal.svg")
const BUTTON_TEXT_COLOR := Color("f4e2b2")
const TEXT_MUTED := Color("b8c9ad")
const TEXT_BODY := Color("d8d0b0")
const PANEL_FILL := Color(0.055, 0.07, 0.052, 0.94)
const CARD_FILL := Color(0.04, 0.05, 0.043, 0.92)
const CARD_BORDER := Color("7e6846")
const AUDIO_VOLUME_MIN_DB := -32.0

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

var codex_button: Button
var upgrades_button: Button
var settings_button: Button
var info_overlay: Control
var overlay_title_label: Label
var overlay_subtitle_label: Label
var overlay_content: VBoxContainer

var upgrade_catalog: Array[Resource] = [
	preload("res://resources/upgrades/damage.tres"),
	preload("res://resources/upgrades/fire_rate.tres"),
	preload("res://resources/upgrades/pierce.tres"),
	preload("res://resources/upgrades/projectiles.tres"),
	preload("res://resources/upgrades/magazine_size.tres"),
	preload("res://resources/upgrades/reload_speed.tres"),
	preload("res://resources/upgrades/scatter_blossom.tres"),
	preload("res://resources/upgrades/flywheel.tres"),
	preload("res://resources/upgrades/drone.tres"),
	preload("res://resources/upgrades/range.tres"),
	preload("res://resources/upgrades/move_speed.tres"),
	preload("res://resources/upgrades/max_health.tres"),
	preload("res://resources/upgrades/sword_rain.tres"),
	preload("res://resources/upgrades/heal.tres")
]

func _ready() -> void:
	AudioManager.play_music_by_key(&"menu")
	start_button.pressed.connect(_on_start_button_pressed)
	_build_corner_actions()
	_build_info_overlay()
	_apply_style()

func _unhandled_input(event: InputEvent) -> void:
	if info_overlay != null and info_overlay.visible and event.is_action_pressed("ui_cancel"):
		_hide_info_overlay()
		get_viewport().set_input_as_handled()

func _on_start_button_pressed() -> void:
	AudioManager.play_ui_by_key(&"button_click")
	GameManager.clear_performance_test()
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func _apply_style() -> void:
	title_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.035, 0.018, 0.95))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	_set_centered_button_content(start_button, ICON_START, 36, 14, 32)
	_style_button(start_button, Color("8a4b27"), Color("d9b56b"))
	_style_button(codex_button, Color("3b332d"), Color("8e8069"), 22)
	_style_button(upgrades_button, Color("3b332d"), Color("8e8069"), 22)
	_style_button(settings_button, Color("3b332d"), Color("8e8069"), 22)

func _build_corner_actions() -> void:
	var actions := HBoxContainer.new()
	actions.name = "CornerActions"
	# 只锚定右上角
	actions.anchor_right = 1.0
	actions.anchor_top = 0.0
	# 距离右侧的间距
	actions.offset_right = -320.0
	actions.offset_top = 22.0
	# 设置合适的大小
	actions.custom_minimum_size = Vector2(350, 52)
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)

	codex_button = _create_corner_button("图鉴", ICON_CODEX)
	codex_button.pressed.connect(_show_codex)
	actions.add_child(codex_button)

	upgrades_button = _create_corner_button("升级", ICON_UPGRADE)
	upgrades_button.pressed.connect(_show_upgrade_reference)
	actions.add_child(upgrades_button)

	settings_button = _create_corner_button("设置", ICON_SETTINGS)
	settings_button.pressed.connect(_show_settings)
	actions.add_child(settings_button)

func _create_corner_button(label_text: String, texture: Texture2D) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(124, 52)
	button.text = label_text
	_set_centered_button_content(button, texture, 28, 10, 22) # 增大图标和字体
	return button

func _build_info_overlay() -> void:
	info_overlay = Control.new()
	info_overlay.name = "InfoOverlay"
	info_overlay.visible = false
	info_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(info_overlay)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.015, 0.012, 0.008, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	info_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.08
	panel.anchor_top = 0.1
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.9
	panel.add_theme_stylebox_override("panel", _panel_box(PANEL_FILL, Color("b99a58"), 20, 3))
	info_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	overlay_title_label = Label.new()
	overlay_title_label.add_theme_font_size_override("font_size", 30)
	overlay_title_label.add_theme_color_override("font_color", Color("fff0c6"))
	title_box.add_child(overlay_title_label)

	overlay_subtitle_label = Label.new()
	overlay_subtitle_label.add_theme_font_size_override("font_size", 15)
	overlay_subtitle_label.add_theme_color_override("font_color", TEXT_MUTED)
	title_box.add_child(overlay_subtitle_label)

	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(120, 46)
	close_button.text = "关闭"
	_set_centered_button_content(close_button, ICON_BACK, 22, 8, 17)
	_style_button(close_button, Color("3b332d"), Color("8e8069"), 17)
	close_button.pressed.connect(_hide_info_overlay)
	header.add_child(close_button)

	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	overlay_content = VBoxContainer.new()
	overlay_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_content.add_theme_constant_override("separation", 14)
	scroll.add_child(overlay_content)

func _show_codex() -> void:
	AudioManager.play_sfx_by_key(&"upgrade_panel_open", -5.0)
	_open_info_overlay("图鉴", "查看主角与各关卡已配置敌人")
	_add_section_title(overlay_content, "主角")
	var character_grid := _create_grid(2)
	overlay_content.add_child(character_grid)
	for character_data in GameManager.character_catalog:
		character_grid.add_child(_create_character_card(character_data))

	_add_section_title(overlay_content, "敌人")
	var enemy_grid := _create_grid(2)
	overlay_content.add_child(enemy_grid)
	for entry in _get_enemy_entries():
		enemy_grid.add_child(_create_enemy_card(entry))

func _show_upgrade_reference() -> void:
	AudioManager.play_sfx_by_key(&"upgrade_panel_open", -5.0)
	_open_info_overlay("升级", "查看所有可获得升级，以及每级累计效果")
	for upgrade in upgrade_catalog:
		overlay_content.add_child(_create_upgrade_card(upgrade))

func _show_settings() -> void:
	AudioManager.play_sfx_by_key(&"upgrade_panel_open", -5.0)
	_open_info_overlay("设置", "调整本次游戏的背景音乐与战斗音效")
	overlay_content.add_child(_create_audio_control_card(
		"背景音乐",
		"控制首页、战斗和首领阶段的音乐。",
		&"Music"
	))
	overlay_content.add_child(_create_audio_control_card(
		"战斗音效",
		"控制开火、命中、受伤、升级与首领提示等战斗反馈。",
		&"SFX"
	))

func _open_info_overlay(title_text: String, subtitle_text: String) -> void:
	overlay_title_label.text = title_text
	overlay_subtitle_label.text = subtitle_text
	for child in overlay_content.get_children():
		child.queue_free()
	info_overlay.visible = true

func _hide_info_overlay() -> void:
	AudioManager.play_ui_by_key(&"back")
	info_overlay.visible = false

func _create_audio_control_card(title_text: String, description: String, bus_name: StringName) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 126)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_box(CARD_FILL, Color("a98955"), 14, 2))

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	card.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 3)
	header.add_child(title_box)

	var title := _create_label(title_text, 22, Color("fff0c6"))
	title_box.add_child(title)

	var desc := _create_label(description, 14, TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(desc)

	var toggle := CheckButton.new()
	toggle.custom_minimum_size = Vector2(92, 42)
	toggle.text = "开启"
	toggle.button_pressed = _is_audio_bus_enabled(bus_name)
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	header.add_child(toggle)

	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 12)
	layout.add_child(slider_row)

	var volume_label := _create_label("音量", 16, TEXT_BODY)
	volume_label.custom_minimum_size = Vector2(48, 0)
	slider_row.add_child(volume_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = round(_get_audio_bus_volume(bus_name) * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.editable = toggle.button_pressed
	slider_row.add_child(slider)

	var value_label := _create_label("", 16, Color("fff0c6"))
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider_row.add_child(value_label)
	_update_audio_value_label(value_label, slider.value, toggle.button_pressed)

	toggle.toggled.connect(_on_audio_toggle_toggled.bind(bus_name, slider, value_label))
	slider.value_changed.connect(_on_audio_slider_changed.bind(bus_name, value_label))
	return card

func _on_audio_toggle_toggled(enabled: bool, bus_name: StringName, slider: HSlider, value_label: Label) -> void:
	_set_audio_bus_enabled(bus_name, enabled)
	slider.editable = enabled
	_update_audio_value_label(value_label, slider.value, enabled)
	AudioManager.play_ui_by_key(&"button_click")

func _on_audio_slider_changed(value: float, bus_name: StringName, value_label: Label) -> void:
	_set_audio_bus_volume(bus_name, value / 100.0)
	_update_audio_value_label(value_label, value, _is_audio_bus_enabled(bus_name))

func _set_audio_bus_enabled(bus_name: StringName, enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not enabled)

func _is_audio_bus_enabled(bus_name: StringName) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	return bus_index < 0 or not AudioServer.is_bus_mute(bus_index)

func _set_audio_bus_volume(bus_name: StringName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var clamped := clampf(volume, 0.0, 1.0)
	var volume_db := AUDIO_VOLUME_MIN_DB if clamped <= 0.0 else linear_to_db(clamped)
	AudioServer.set_bus_volume_db(bus_index, volume_db)

func _get_audio_bus_volume(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 1.0
	var volume_db := AudioServer.get_bus_volume_db(bus_index)
	if volume_db <= AUDIO_VOLUME_MIN_DB:
		return 0.0
	return clampf(db_to_linear(volume_db), 0.0, 1.0)

func _update_audio_value_label(label: Label, value: float, enabled: bool) -> void:
	label.text = "%d%%" % int(round(value)) if enabled else "关闭"

func _create_character_card(character_data: Resource) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 132)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected: bool = GameManager.selected_character != null and GameManager.selected_character.character_id == character_data.character_id
	var border: Color = Color("d9b56b") if selected else CARD_BORDER
	card.add_theme_stylebox_override("panel", _panel_box(CARD_FILL, border, 12, 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(104, 104)
	portrait_frame.add_theme_stylebox_override("panel", _panel_box(Color(0.025, 0.03, 0.026, 0.88), Color("4f5d45"), 6, 2))
	row.add_child(portrait_frame)

	var portrait_area := Control.new()
	portrait_area.clip_contents = true
	portrait_frame.add_child(portrait_area)
	if character_data != null:
		_add_full_rect_texture(portrait_area, _make_sprite_frame(character_data.body_texture), 4)
		_add_full_rect_texture(portrait_area, character_data.rifle_texture, 4)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 6)
	row.add_child(text_box)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	text_box.add_child(name_row)

	var name_label := _create_label(character_data.display_name, 22, Color("fff0c6"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	if selected:
		name_row.add_child(_create_badge("当前选择", Color("594728"), Color("d9b56b")))

	var desc_label := _create_label(character_data.description, 15, TEXT_MUTED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(desc_label)
	return card

func _create_enemy_card(entry: Dictionary) -> Control:
	var enemy_data: Resource = entry["data"]
	var is_boss := bool(entry["boss"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 142)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border: Color = enemy_data.color.lightened(0.18) if enemy_data != null else CARD_BORDER
	card.add_theme_stylebox_override("panel", _panel_box(CARD_FILL, border, 12, 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(86, 86)
	icon_frame.add_theme_stylebox_override("panel", _panel_box(Color(0.02, 0.024, 0.022, 0.86), border, 7, 2))
	row.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.texture = _get_enemy_texture(enemy_data)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 5)
	row.add_child(text_box)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	text_box.add_child(name_row)

	var name_label := _create_label(enemy_data.display_name, 21, Color("fff0c6"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	name_row.add_child(_create_badge(_get_enemy_role_text(enemy_data, is_boss), Color("3b332d"), border))

	var stat_label := _create_label(
		"生命 %d  攻击 %d  移速 %d  经验 %d" % [
			int(enemy_data.max_health),
			int(enemy_data.damage),
			int(enemy_data.move_speed),
			enemy_data.exp_reward
		],
		14,
		TEXT_BODY
	)
	text_box.add_child(stat_label)

	var range_label := _create_label(_get_enemy_attack_text(enemy_data), 14, TEXT_MUTED)
	text_box.add_child(range_label)

	var level_label := _create_label("出现关卡：%s" % _join_array(entry["levels"]), 13, Color("aeb89e"))
	level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(level_label)
	return card

func _create_upgrade_card(upgrade: Resource) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 184)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_box(CARD_FILL, Color("a98955"), 14, 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(96, 96)
	icon_frame.add_theme_stylebox_override("panel", _panel_box(Color(0.025, 0.03, 0.026, 0.9), Color("7e6846"), 8, 2))
	row.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.texture = _get_upgrade_icon(upgrade)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	row.add_child(body)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	body.add_child(header)

	var title := _create_label(upgrade.title, 22, Color("fff0c6"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_create_badge(_get_upgrade_type(upgrade), Color("3b332d"), Color("a98955")))
	header.add_child(_create_badge("最高 Lv.%d" % upgrade.max_level, Color("594728"), Color("d9b56b")))

	var desc := _create_label(upgrade.description, 15, TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(desc)

	var prereq := _get_upgrade_prerequisite_text(upgrade)
	if not prereq.is_empty():
		var prereq_label := _create_label(prereq, 13, Color("ffdf7a"))
		body.add_child(prereq_label)

	var levels := VBoxContainer.new()
	levels.add_theme_constant_override("separation", 4)
	body.add_child(levels)
	for level in range(1, upgrade.max_level + 1):
		var level_label := _create_label("Lv.%d  %s" % [level, _get_upgrade_level_effect(upgrade, level)], 14, TEXT_BODY)
		level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		levels.add_child(level_label)
	return card

func _get_enemy_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var by_id := {}
	for level_data in GameManager.level_catalog:
		for enemy_data in level_data.enemy_catalog:
			_add_enemy_entry(entries, by_id, enemy_data, level_data.title, false)
		if level_data.boss_data != null:
			_add_enemy_entry(entries, by_id, level_data.boss_data, level_data.title, true)
	return entries

func _add_enemy_entry(entries: Array[Dictionary], by_id: Dictionary, enemy_data: Resource, level_title: String, is_boss: bool) -> void:
	if enemy_data == null:
		return
	var key := String(enemy_data.enemy_id)
	var entry: Dictionary
	if by_id.has(key):
		entry = by_id[key]
	else:
		entry = {"data": enemy_data, "levels": [], "boss": false}
		by_id[key] = entry
		entries.append(entry)
	var levels: Array = entry["levels"]
	if not levels.has(level_title):
		levels.append(level_title)
	if is_boss:
		entry["boss"] = true

func _get_enemy_role_text(enemy_data: Resource, listed_as_boss: bool) -> String:
	if listed_as_boss or enemy_data.boss:
		return "首领"
	if enemy_data.ranged:
		return "远程"
	if enemy_data.elite:
		return "精英"
	return "近战"

func _get_enemy_attack_text(enemy_data: Resource) -> String:
	if enemy_data.ranged:
		return "攻击距离 %d  冷却 %.1fs" % [int(enemy_data.attack_range), enemy_data.attack_cooldown]
	return "近战距离 %d  冷却 %.1fs" % [int(enemy_data.attack_range), enemy_data.attack_cooldown]

func _get_upgrade_prerequisite_text(upgrade: Resource) -> String:
	if String(upgrade.upgrade_id).begins_with("drone_"):
		return "前置：需要先获得“解锁无人机”。"
	return ""

func _get_upgrade_level_effect(upgrade: Resource, level: int) -> String:
	match upgrade.stat_key:
		&"damage_multiplier":
			return _format_multiplier_effect("伤害", upgrade.amount, level)
		&"fire_rate_multiplier":
			return _format_multiplier_effect("射速/命中频率", upgrade.amount, level)
		&"range_multiplier":
			return _format_multiplier_effect("射程/作用半径", upgrade.amount, level)
		&"move_speed_multiplier":
			return _format_multiplier_effect("移动速度", upgrade.amount, level)
		&"drone_damage_multiplier":
			return _format_multiplier_effect("无人机伤害", upgrade.amount, level)
		&"drone_fire_rate_multiplier":
			return _format_multiplier_effect("无人机射速", upgrade.amount, level)
		&"drone_range_multiplier":
			return _format_multiplier_effect("无人机射程", upgrade.amount, level)
		&"max_health":
			var health_bonus := int(upgrade.amount) * level
			return "最大生命 +%d，累计恢复 +%d" % [health_bonus, health_bonus]
		&"projectile_count":
			return "每次射击累计 +%d 发子弹" % (int(upgrade.amount) * level)
		&"pierce":
			return "子弹累计额外穿透 +%d 名敌人" % (int(upgrade.amount) * level)
		&"flywheel_count":
			return "环绕飞轮累计 +%d 个" % (int(upgrade.amount) * level)
		&"drone_unlock":
			return "获得右上方支援无人机，发射激光自动索敌"
		&"scatter_level":
			return _get_scatter_level_effect(level)
		&"drone_upgrade":
			return _get_drone_upgrade_effect(level)
		_:
			return upgrade.description

func _format_multiplier_effect(subject: String, amount: float, level: int) -> String:
	var multiplier := pow(1.0 + amount, level)
	var percent := int(round((multiplier - 1.0) * 100.0))
	return "%s累计 x%.2f（+%d%%）" % [subject, multiplier, percent]

func _get_drone_upgrade_effect(level: int) -> String:
	match level:
		1:
			return "获得右上方支援无人机，发射激光自动索敌"
		2:
			return "激光伤害 x1.3，射程 x1.25"
		3:
			return "灼烧频率提升，射程 x1.25"
		4:
			return "激光宽度翻倍，射程 x1.3"
		5:
			return "激光伤害 x1.3，灼烧频率再次提升，射程 x1.3"
		_:
			return "解锁或强化激光无人机"

func _get_scatter_level_effect(level: int) -> String:
	var beam_length := 360.0 + 35.0 * float(level)
	var beam_width := 46.0 + 6.0 * float(level)
	var dps := 90.0 * (1.0 + 0.18 * float(level))
	var cooldown := maxf(6.5, 9.0 - 0.5 * float(level))
	var sweep_text := "，扫射一圈半" if level >= 3 else "，扫射一圈"
	return "激光长度 %.0f，宽度 %.0f，DPS %.0f，冷却 %.1fs%s" % [beam_length, beam_width, dps, cooldown, sweep_text]

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

func _get_upgrade_icon(upgrade: Resource) -> Texture2D:
	match upgrade.upgrade_id:
		&"damage":
			return ICON_DAMAGE
		&"fire_rate":
			return ICON_FIRE_RATE
		&"range":
			return ICON_RANGE
		&"pierce":
			return ICON_PIERCE
		&"projectiles":
			return ICON_PROJECTILE
		&"scatter_blossom":
			return ICON_SCATTER
		&"flywheel":
			return ICON_FLYWHEEL
		&"drone", &"drone_damage", &"drone_fire_rate", &"drone_range":
			return ICON_DRONE
		&"move_speed":
			return ICON_CODEX
		&"max_health":
			return ICON_HEALTH
		&"sword_rain":
			return ICON_ARROW
		&"heal":
			return ICON_HEAL
		_:
			return ICON_UPGRADE

func _create_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	return grid

func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var label := _create_label(text, 23, Color("e8d99a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _create_badge(text: String, fill: Color, border: Color) -> Control:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _panel_box(fill, border, 6, 1))
	var label := _create_label(text, 13, Color("fff0c6"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge

func _add_full_rect_texture(parent: Control, texture: Texture2D, inset: int) -> void:
	if texture == null:
		return
	var image := TextureRect.new()
	image.texture = texture
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = inset
	image.offset_top = inset
	image.offset_right = - inset
	image.offset_bottom = - inset
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func _make_sprite_frame(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, 128, 128)
	return atlas

func _get_enemy_texture(enemy_data: Resource) -> Texture2D:
	if enemy_data == null:
		return null
	if enemy_data.texture != null:
		return enemy_data.texture
	if enemy_data.walk_texture != null:
		return _make_sprite_frame(enemy_data.walk_texture)
	return null

func _join_array(values: Array) -> String:
	var text := ""
	for index in values.size():
		if index > 0:
			text += "、"
		text += String(values[index])
	return text

func _set_centered_button_content(button: Button, texture: Texture2D, icon_size: int, gap: int, font_size: int) -> void:
	var label_text := button.text
	button.text = ""
	button.icon = null

	var existing := button.get_node_or_null("CenteredContent")
	if existing != null:
		button.remove_child(existing)
		existing.queue_free()

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

func _style_button(button: Button, fill: Color, border: Color, font_size: int = 32) -> void: # 增大默认字体
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.12), border.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border.darkened(0.1)))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.08), border.lightened(0.12)))
	button.add_theme_color_override("font_color", Color("f4e2b2"))
	button.add_theme_color_override("font_hover_color", Color("fff0c6"))
	button.add_theme_font_size_override("font_size", font_size)

func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	# 再增加左右边距
	box.content_margin_left = 32
	box.content_margin_right = 32
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box

func _panel_box(fill: Color, border: Color, margin: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(margin)
	box.shadow_color = Color(0, 0, 0, 0.36)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box
