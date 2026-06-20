extends Node

# Placeholder audio API. Streams can be assigned when the audio phase starts.
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	add_child(sfx_player)

func play_music(stream: AudioStream) -> void:
	if stream == null or music_player.stream == stream:
		return
	music_player.stream = stream
	music_player.play()

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func stop_music() -> void:
	music_player.stop()
