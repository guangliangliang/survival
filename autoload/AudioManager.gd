extends Node

const MUSIC := {
	&"menu": "res://assets/audio/music/music_menu_village.ogg",
	&"battle": "res://assets/audio/music/music_battle_patrol.ogg",
	&"boss": "res://assets/audio/music/music_boss_last_defense.ogg",
}

const SFX := {
	&"player_rifle": [
		"res://assets/audio/sfx/sfx_player_rifle_01.wav",
		"res://assets/audio/sfx/sfx_player_rifle_02.wav",
		"res://assets/audio/sfx/sfx_player_rifle_03.wav",
		"res://assets/audio/sfx/sfx_player_rifle_04.wav",
	],
	&"bullet_hit": [
		"res://assets/audio/sfx/sfx_bullet_hit_01.wav",
		"res://assets/audio/sfx/sfx_bullet_hit_02.wav",
		"res://assets/audio/sfx/sfx_bullet_hit_03.wav",
		"res://assets/audio/sfx/sfx_bullet_hit_04.wav",
	],
	&"enemy_death": [
		"res://assets/audio/sfx/sfx_enemy_death_01.wav",
		"res://assets/audio/sfx/sfx_enemy_death_02.wav",
		"res://assets/audio/sfx/sfx_enemy_death_03.wav",
		"res://assets/audio/sfx/sfx_enemy_death_04.wav",
	],
	&"player_hurt": [
		"res://assets/audio/sfx/sfx_player_hurt_01.wav",
		"res://assets/audio/sfx/sfx_player_hurt_02.wav",
		"res://assets/audio/sfx/sfx_player_hurt_03.wav",
		"res://assets/audio/sfx/sfx_player_hurt_04.wav",
	],
	&"enemy_rifle": [
		"res://assets/audio/sfx/sfx_enemy_rifle_01.wav",
		"res://assets/audio/sfx/sfx_enemy_rifle_02.wav",
		"res://assets/audio/sfx/sfx_enemy_rifle_03.wav",
		"res://assets/audio/sfx/sfx_enemy_rifle_04.wav",
	],
	&"enemy_projectile_pass": [
		"res://assets/audio/sfx/sfx_enemy_projectile_pass1.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_pass2.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_pass3.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_pass4.wav",
	],
	&"enemy_melee_swing": [
		"res://assets/audio/sfx/sfx_enemy_melee_swing_01.wav",
		"res://assets/audio/sfx/sfx_enemy_melee_swing_02.wav",
		"res://assets/audio/sfx/sfx_enemy_melee_swing_03.wav",
		"res://assets/audio/sfx/sfx_enemy_melee_swing_04.wav",
	],
	&"porcupine_thorn": [
		"res://assets/audio/sfx/sfx_porcupine_thorn_shot_01.wav",
		"res://assets/audio/sfx/sfx_porcupine_thorn_shot_02.wav",
		"res://assets/audio/sfx/sfx_porcupine_thorn_shot_03.wav",
		"res://assets/audio/sfx/sfx_porcupine_thorn_shot_04.wav",
	],
	&"wizard_orb": [
		"res://assets/audio/sfx/sfx_wizard_orb_cast_01.wav",
		"res://assets/audio/sfx/sfx_wizard_orb_cast_02.wav",
		"res://assets/audio/sfx/sfx_wizard_orb_cast_03.wav",
		"res://assets/audio/sfx/sfx_wizard_orb_cast_04.wav",
	],
	&"enemy_projectile_land": [
		"res://assets/audio/sfx/sfx_enemy_projectile_land_01.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_land_02.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_land_03.wav",
		"res://assets/audio/sfx/sfx_enemy_projectile_land_04.wav",
	],
	&"flywheel_loop": [
		"res://assets/audio/sfx/sfx_flywheel_loop1.wav",
		"res://assets/audio/sfx/sfx_flywheel_loop2.wav",
		"res://assets/audio/sfx/sfx_flywheel_loop3.wav",
		"res://assets/audio/sfx/sfx_flywheel_loop4.wav",
	],
	&"flywheel_hit": [
		"res://assets/audio/sfx/sfx_flywheel_hit_01.wav",
		"res://assets/audio/sfx/sfx_flywheel_hit_02.wav",
		"res://assets/audio/sfx/sfx_flywheel_hit_03.wav",
		"res://assets/audio/sfx/sfx_flywheel_hit_04.wav",
	],
	&"drone_shot": [
		"res://assets/audio/sfx/sfx_drone_shot_01.wav",
		"res://assets/audio/sfx/sfx_drone_shot_02.wav",
		"res://assets/audio/sfx/sfx_drone_shot_03.wav",
		"res://assets/audio/sfx/sfx_drone_shot_04.wav",
	],
	&"exp_pickup": [
		"res://assets/audio/sfx/sfx_exp_pickup_01.wav",
		"res://assets/audio/sfx/sfx_exp_pickup_02.wav",
		"res://assets/audio/sfx/sfx_exp_pickup_03.wav",
		"res://assets/audio/sfx/sfx_exp_pickup_04.wav",
	],
	&"level_up": ["res://assets/audio/sfx/sfx_level_up.wav"],
	&"upgrade_select": ["res://assets/audio/sfx/sfx_upgrade_select.wav"],
	&"upgrade_panel_open": ["res://assets/audio/sfx/sfx_upgrade_panel_open.wav"],
	&"weapon_unlock": ["res://assets/audio/sfx/sfx_weapon_unlock.wav"],
	&"boss_warning": ["res://assets/audio/sfx/sfx_boss_warning.wav"],
	&"boss_hit": [
		"res://assets/audio/sfx/sfx_boss_hit_01.wav",
		"res://assets/audio/sfx/sfx_boss_hit_02.wav",
		"res://assets/audio/sfx/sfx_boss_hit_03.wav",
		"res://assets/audio/sfx/sfx_boss_hit_04.wav",
	],
	&"boss_death": ["res://assets/audio/sfx/sfx_boss_death.wav"],
	&"victory": ["res://assets/audio/music/sfx_victory.ogg"],
	&"defeat": ["res://assets/audio/music/sfx_defeat.ogg"],
}

const UI := {
	&"button_click": "res://assets/audio/sfx/ui_button_click.wav",
	&"back": "res://assets/audio/sfx/ui_back.wav",
	&"pause": "res://assets/audio/sfx/ui_pause.wav",
	&"resume": "res://assets/audio/sfx/ui_resume.wav",
	&"invalid": "res://assets/audio/sfx/ui_invalid.wav",
}

const SFX_POOL_SIZE := 18
const UI_POOL_SIZE := 6

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var ui_pool: Array[AudioStreamPlayer] = []
var stream_cache: Dictionary = {}
var missing_paths: Dictionary = {}
var current_music_key: StringName = &""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	_build_pool(sfx_pool, SFX_POOL_SIZE, &"SFX")
	_build_pool(ui_pool, UI_POOL_SIZE, &"UI")

func play_music_by_key(key: StringName) -> void:
	if current_music_key == key and music_player.playing:
		return
	var path := String(MUSIC.get(key, ""))
	if path.is_empty():
		return
	play_music(_get_stream(path))
	current_music_key = key

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func play_sfx_by_key(key: StringName, volume_db: float = 0.0) -> void:
	var paths: Array = SFX.get(key, [])
	if paths.is_empty():
		return
	play_sfx(_get_stream(String(paths.pick_random())), volume_db)

func play_ui_by_key(key: StringName, volume_db: float = 0.0) -> void:
	var path := String(UI.get(key, ""))
	if path.is_empty():
		return
	_play_on_pool(ui_pool, _get_stream(path), volume_db)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	_play_on_pool(sfx_pool, stream, volume_db)

func stop_music() -> void:
	music_player.stop()
	current_music_key = &""

func _build_pool(pool: Array[AudioStreamPlayer], size: int, bus_name: StringName) -> void:
	for index in size:
		var player := AudioStreamPlayer.new()
		player.bus = bus_name
		add_child(player)
		pool.append(player)

func _play_on_pool(pool: Array[AudioStreamPlayer], stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	var player := _get_available_player(pool)
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func _get_available_player(pool: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player
	return pool[0]

func _get_stream(path: String) -> AudioStream:
	if stream_cache.has(path):
		return stream_cache[path]
	if not ResourceLoader.exists(path):
		if not missing_paths.has(path):
			missing_paths[path] = true
			push_warning("Audio resource not found: %s" % path)
		return null
	var stream := load(path) as AudioStream
	stream_cache[path] = stream
	return stream
