extends Control

const SFX_DIR := "res://assets/audio/sfx"
const SKIP_EXTENSIONS := [".import"]
const DISPLAY_NAMES := {
	"sfx_player_rifle.wav": "玩家步枪开火",
	"sfx_bullet_hit.wav": "子弹命中敌人",
	"sfx_enemy_death.wav": "敌人死亡",
	"sfx_player_hurt.wav": "玩家受伤",
	"sfx_enemy_rifle.wav": "敌人枪手射击",
	"sfx_enemy_projectile_pass.wav": "敌方弹丸掠过",
	"sfx_enemy_melee_swing.wav": "近战敌人挥击",
	"sfx_porcupine_thorn_shot.wav": "豪猪尖刺发射",
	"sfx_wizard_orb_cast.wav": "巫师法球发射",
	"sfx_enemy_projectile_land.wav": "敌方弹丸落地",
	"sfx_flywheel_loop.wav": "环绕飞轮旋转",
	"sfx_flywheel_hit.wav": "飞轮切中敌人",
	"sfx_weapon_unlock.wav": "新武器解锁",
	"sfx_exp_pickup.wav": "经验宝石拾取",
	"sfx_level_up.wav": "升级",
	"sfx_upgrade_select.wav": "选择升级卡",
	"sfx_upgrade_panel_open.wav": "升级卡出现",
	"ui_invalid.wav": "无法选择或操作无效",
	"sfx_boss_warning.wav": "Boss 出现警告",
	"sfx_boss_hit.wav": "Boss 受击",
	"sfx_boss_death.wav": "Boss 死亡",
}

var sfx_items: Array[Dictionary] = []
var selected_index := -1

var player: AudioStreamPlayer
var list: ItemList
var title_label: Label
var detail_label: Label
var play_button: Button
var pause_button: Button
var stop_button: Button
var replay_button: Button
var volume_slider: HSlider
var progress_bar: ProgressBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_stop_audio_manager_players()
	_build_player()
	_build_ui()
	_load_sfx_items()
	_select_first_item()
	set_process(true)

func _process(_delta: float) -> void:
	_update_progress()
	_update_button_states()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE and is_instance_valid(player):
		player.stop()

func _build_player() -> void:
	player = AudioStreamPlayer.new()
	player.bus = &"SFX"
	add_child(player)

func _stop_audio_manager_players() -> void:
	AudioManager.stop_music()
	for sfx_player in AudioManager.sfx_pool:
		sfx_player.stop()
	for ui_player in AudioManager.ui_pool:
		ui_player.stop()

func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 18)
	root.add_child(main)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(390, 0)
	main.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_panel.add_child(left_margin)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_box)

	var list_label := Label.new()
	list_label.text = "音效列表"
	list_label.add_theme_font_size_override("font_size", 24)
	left_box.add_child(list_label)

	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.select_mode = ItemList.SELECT_SINGLE
	list.item_selected.connect(_on_item_selected)
	left_box.add_child(list)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 18)
	right_margin.add_theme_constant_override("margin_top", 18)
	right_margin.add_theme_constant_override("margin_right", 18)
	right_margin.add_theme_constant_override("margin_bottom", 18)
	right_panel.add_child(right_margin)

	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_box)

	title_label = Label.new()
	title_label.text = "音效测试"
	title_label.add_theme_font_size_override("font_size", 32)
	right_box.add_child(title_label)

	detail_label = Label.new()
	detail_label.text = "选择一个音效。"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_box.add_child(detail_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 24)
	progress_bar.show_percentage = false
	right_box.add_child(progress_bar)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	right_box.add_child(buttons)

	play_button = _make_button("播放")
	play_button.pressed.connect(_on_play_pressed)
	buttons.add_child(play_button)

	pause_button = _make_button("暂停")
	pause_button.pressed.connect(_on_pause_pressed)
	buttons.add_child(pause_button)

	stop_button = _make_button("停止")
	stop_button.pressed.connect(_on_stop_pressed)
	buttons.add_child(stop_button)

	replay_button = _make_button("重播")
	replay_button.pressed.connect(_on_replay_pressed)
	buttons.add_child(replay_button)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 10)
	right_box.add_child(volume_row)

	var volume_label := Label.new()
	volume_label.text = "音量"
	volume_label.custom_minimum_size = Vector2(76, 0)
	volume_row.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = -24.0
	volume_slider.max_value = 6.0
	volume_slider.step = 1.0
	volume_slider.value = 0.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	var hint := Label.new()
	hint.text = "进入本页会停止背景音乐，只播放当前选中的音效。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.72, 0.64)
	right_box.add_child(hint)

	_apply_style(left_panel)
	_apply_style(right_panel)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(110, 42)
	button.text = text
	return button

func _apply_style(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("242820")
	box.border_color = Color("8d7754")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", box)

func _load_sfx_items() -> void:
	var files := DirAccess.get_files_at(SFX_DIR)
	files.sort()
	for file_name in files:
		if _should_skip_file(file_name):
			continue
		var path := "%s/%s" % [SFX_DIR, file_name]
		if not ResourceLoader.exists(path):
			continue
		sfx_items.append({
			"display_name": _get_display_name(file_name),
			"name": file_name,
			"path": path,
		})
		list.add_item("%s\n%s" % [_get_display_name(file_name), file_name])
	if sfx_items.is_empty():
		detail_label.text = "没有在 %s 找到音效文件。" % SFX_DIR

func _should_skip_file(file_name: String) -> bool:
	for extension in SKIP_EXTENSIONS:
		if file_name.ends_with(extension):
			return true
	return not (file_name.ends_with(".wav") or file_name.ends_with(".ogg") or file_name.ends_with(".mp3"))

func _get_display_name(file_name: String) -> String:
	return String(DISPLAY_NAMES.get(file_name, file_name.get_basename()))

func _select_first_item() -> void:
	if sfx_items.is_empty():
		return
	list.select(0)
	_select_item(0)

func _on_item_selected(index: int) -> void:
	_select_item(index)

func _select_item(index: int) -> void:
	if index < 0 or index >= sfx_items.size():
		return
	selected_index = index
	player.stop()
	player.stream_paused = false
	var item := sfx_items[index]
	var stream := load(String(item["path"])) as AudioStream
	player.stream = stream
	title_label.text = String(item["display_name"])
	detail_label.text = "%s\n%s\n%s" % [String(item["name"]), String(item["path"]), _get_stream_detail(stream)]
	_update_progress()
	_update_button_states()

func _get_stream_detail(stream: AudioStream) -> String:
	if stream == null:
		return "无法加载这个音频。"
	var length := stream.get_length()
	if length <= 0.0:
		return "时长未知"
	return "时长 %.2f 秒" % length

func _on_play_pressed() -> void:
	if player.stream == null:
		return
	if player.playing and player.stream_paused:
		player.stream_paused = false
	elif not player.playing:
		player.play()

func _on_pause_pressed() -> void:
	if player.stream == null or not player.playing:
		return
	player.stream_paused = not player.stream_paused

func _on_stop_pressed() -> void:
	player.stop()
	player.stream_paused = false
	_update_progress()

func _on_replay_pressed() -> void:
	if player.stream == null:
		return
	player.stop()
	player.stream_paused = false
	player.play()

func _on_volume_changed(value: float) -> void:
	player.volume_db = value

func _update_progress() -> void:
	if player.stream == null:
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		return
	var length := maxf(player.stream.get_length(), 0.01)
	progress_bar.max_value = length
	progress_bar.value = clampf(player.get_playback_position(), 0.0, length)

func _update_button_states() -> void:
	var has_stream := player.stream != null
	play_button.disabled = not has_stream
	pause_button.disabled = not has_stream or not player.playing
	stop_button.disabled = not has_stream or not player.playing
	replay_button.disabled = not has_stream
	pause_button.text = "继续" if player.playing and player.stream_paused else "暂停"
