extends Control

const WAVE_RESOURCES: Array[Resource] = [
	preload("res://resources/waves/village_wave1.tres"),
]

@onready var wave_warning_ui: Control = $WaveWarningUI
@onready var wave_warning_panel: PanelContainer = $WaveWarningUI/Panel
@onready var wave_warning_label: Label = $WaveWarningUI/Panel/VBox/WarningLabel
@onready var wave_name_label: Label = $WaveWarningUI/Panel/VBox/WaveNameLabel
@onready var wave_countdown_label: Label = $WaveWarningUI/Panel/VBox/CountdownLabel
@onready var wave_top_scan: ColorRect = $WaveWarningUI/Panel/VBox/TopScanBar
@onready var wave_bottom_scan: ColorRect = $WaveWarningUI/Panel/VBox/BottomScanBar
@onready var trigger_button: Button = $ControlPanel/Margin/VBox/TriggerButton
@onready var wave_list: VBoxContainer = $ControlPanel/Margin/VBox/WaveList

var wave_countdown_timer: Timer = Timer.new()
var wave_countdown: float = 0.0
var wave_countdown_last_int: int = -1

var wave_warning_intro_tween: Tween
var wave_warning_pulse_tween: Tween
var wave_warning_scan_tween: Tween
var wave_warning_outro_tween: Tween
var wave_countdown_tick_tween: Tween

var current_wave: WaveEvent = null

func _ready() -> void:
	add_child(wave_countdown_timer)
	wave_countdown_timer.one_shot = false
	wave_countdown_timer.wait_time = 0.1
	wave_countdown_timer.timeout.connect(_on_wave_countdown_timer_timeout)
	wave_countdown_timer.stop()
	wave_warning_ui.visible = false
	trigger_button.pressed.connect(_on_trigger_pressed)
	_build_wave_list()

func _build_wave_list() -> void:
	for child in wave_list.get_children():
		child.queue_free()
	for res in WAVE_RESOURCES:
		var wave := res as WaveEvent
		if wave == null:
			continue
		var btn := Button.new()
		btn.text = "%s (%d秒)" % [wave.display_name, int(wave.warning_time)]
		btn.pressed.connect(_on_wave_selected.bind(wave))
		wave_list.add_child(btn)

func _on_wave_selected(wave: WaveEvent) -> void:
	_show_wave_warning(wave)

func _on_trigger_pressed() -> void:
	var wave := current_wave
	if wave == null and not WAVE_RESOURCES.is_empty():
		wave = WAVE_RESOURCES[0] as WaveEvent
	if wave != null:
		_show_wave_warning(wave)

func _show_wave_warning(wave: WaveEvent) -> void:
	current_wave = wave
	wave_countdown = wave.warning_time
	wave_name_label.text = wave.display_name
	wave_countdown_last_int = -1
	_update_wave_countdown_label()
	_kill_wave_tweens()
	wave_warning_ui.visible = true
	wave_warning_panel.modulate = Color(1, 1, 1, 0)
	wave_warning_panel.scale = Vector2(0.7, 0.7)
	wave_warning_panel.pivot_offset = wave_warning_panel.size * 0.5
	wave_warning_label.scale = Vector2.ONE
	wave_warning_label.modulate = Color(1, 0.4, 0.4, 1)
	wave_top_scan.modulate.a = 1.0
	wave_bottom_scan.modulate.a = 0.3
	wave_countdown_label.scale = Vector2.ONE
	wave_countdown_timer.start()

	wave_warning_intro_tween = create_tween()
	wave_warning_intro_tween.set_parallel(true)
	wave_warning_intro_tween.tween_property(wave_warning_panel, "modulate:a", 1.0, 0.30)
	wave_warning_intro_tween.tween_property(wave_warning_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	wave_warning_intro_tween.chain().tween_callback(_start_wave_pulse)
	wave_warning_intro_tween.tween_callback(_start_wave_scan)

func _start_wave_pulse() -> void:
	if wave_warning_pulse_tween != null and wave_warning_pulse_tween.is_valid():
		wave_warning_pulse_tween.kill()
	wave_warning_pulse_tween = create_tween()
	wave_warning_pulse_tween.set_loops()
	wave_warning_pulse_tween.set_parallel(true)
	wave_warning_pulse_tween.tween_property(wave_warning_label, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE)
	wave_warning_pulse_tween.tween_property(wave_warning_label, "modulate", Color(1, 0.75, 0.5, 1), 0.55).set_trans(Tween.TRANS_SINE)
	wave_warning_pulse_tween.chain()
	wave_warning_pulse_tween.tween_property(wave_warning_label, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	wave_warning_pulse_tween.tween_property(wave_warning_label, "modulate", Color(1, 0.4, 0.4, 1), 0.55).set_trans(Tween.TRANS_SINE)

func _start_wave_scan() -> void:
	if wave_warning_scan_tween != null and wave_warning_scan_tween.is_valid():
		wave_warning_scan_tween.kill()
	wave_warning_scan_tween = create_tween()
	wave_warning_scan_tween.set_loops()
	wave_warning_scan_tween.set_parallel(true)
	wave_warning_scan_tween.tween_property(wave_top_scan, "modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_LINEAR)
	wave_warning_scan_tween.tween_property(wave_bottom_scan, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_LINEAR)
	wave_warning_scan_tween.chain()
	wave_warning_scan_tween.tween_property(wave_top_scan, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_LINEAR)
	wave_warning_scan_tween.tween_property(wave_bottom_scan, "modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_LINEAR)

func _kill_wave_tweens() -> void:
	for t in [wave_warning_intro_tween, wave_warning_pulse_tween, wave_warning_scan_tween, wave_warning_outro_tween, wave_countdown_tick_tween]:
		if t != null and t.is_valid():
			t.kill()
	wave_warning_intro_tween = null
	wave_warning_pulse_tween = null
	wave_warning_scan_tween = null
	wave_warning_outro_tween = null
	wave_countdown_tick_tween = null

func _play_outro() -> void:
	wave_countdown_timer.stop()
	_kill_wave_tweens()
	if not wave_warning_ui.visible:
		return
	wave_warning_outro_tween = create_tween()
	wave_warning_outro_tween.set_parallel(true)
	wave_warning_outro_tween.tween_property(wave_warning_panel, "scale", Vector2(1.15, 1.15), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wave_warning_outro_tween.tween_property(wave_warning_panel, "modulate:a", 0.0, 0.20)
	wave_warning_outro_tween.chain().tween_callback(_on_outro_finished)

func _on_outro_finished() -> void:
	wave_warning_ui.visible = false
	wave_warning_panel.scale = Vector2.ONE
	wave_warning_panel.modulate = Color.WHITE
	wave_warning_label.scale = Vector2.ONE
	wave_warning_label.modulate = Color(1, 0.4, 0.4, 1)
	wave_countdown_label.scale = Vector2.ONE

func _on_wave_countdown_timer_timeout() -> void:
	wave_countdown -= 0.1
	if wave_countdown <= 0:
		wave_countdown = 0
		wave_countdown_timer.stop()
		_update_wave_countdown_label()
		_play_outro()
		return
	_update_wave_countdown_label()

func _update_wave_countdown_label() -> void:
	var seconds := int(ceil(wave_countdown))
	wave_countdown_label.text = "%d秒" % max(0, seconds)
	if seconds >= 3:
		wave_countdown_label.modulate = Color(1, 1, 0.7)
	elif seconds == 2:
		wave_countdown_label.modulate = Color(1, 0.7, 0.3)
	else:
		wave_countdown_label.modulate = Color(1, 0.3, 0.25)
	if seconds != wave_countdown_last_int and seconds > 0 and wave_warning_ui.visible:
		wave_countdown_last_int = seconds
		if wave_countdown_tick_tween != null and wave_countdown_tick_tween.is_valid():
			wave_countdown_tick_tween.kill()
		wave_countdown_tick_tween = create_tween()
		wave_countdown_tick_tween.tween_property(wave_countdown_label, "scale", Vector2(1.25, 1.25), 0.08)
		wave_countdown_tick_tween.tween_property(wave_countdown_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
