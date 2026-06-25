extends Node2D

const IMPACT_TEXTURE := preload("res://assets/images/effects/fx_bullet_impact.png")
const DEATH_TEXTURE := preload("res://assets/images/effects/fx_death_puff.png")

@export var pool_size: int = 48

var effects: Array[Sprite2D] = []

func _ready() -> void:
	add_to_group("visual_effects")
	for index in pool_size:
		var sprite := Sprite2D.new()
		sprite.visible = false
		sprite.centered = true
		sprite.z_index = 12
		add_child(sprite)
		effects.append(sprite)

func _process(delta: float) -> void:
	for sprite in effects:
		if not sprite.visible:
			continue
		var remaining: float = float(sprite.get_meta("remaining", 0.0)) - delta
		var duration: float = float(sprite.get_meta("duration", 0.2))
		var frames: int = int(sprite.get_meta("frames", 1))
		var frame_width: int = int(sprite.get_meta("frame_width", 32))
		var frame_height: int = int(sprite.get_meta("frame_height", 32))
		var elapsed := duration - remaining
		var frame := clampi(int(elapsed / duration * frames), 0, frames - 1)
		sprite.region_rect = Rect2(frame * frame_width, 0, frame_width, frame_height)
		sprite.modulate.a = clampf(remaining / duration * 1.6, 0.0, 1.0)
		sprite.set_meta("remaining", remaining)
		if remaining <= 0.0:
			sprite.visible = false

func play_impact(world_position: Vector2) -> void:
	_play_strip(IMPACT_TEXTURE, world_position, 4, Vector2i(32, 32), 0.18)

func play_death_puff(world_position: Vector2) -> void:
	_play_strip(DEATH_TEXTURE, world_position, 6, Vector2i(64, 64), 0.42)

func _play_strip(texture: Texture2D, world_position: Vector2, frames: int, frame_size: Vector2i, duration: float) -> void:
	for sprite in effects:
		if sprite.visible:
			continue
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_size.x, frame_size.y)
		sprite.global_position = world_position
		sprite.modulate = Color.WHITE
		sprite.set_meta("frames", frames)
		sprite.set_meta("frame_width", frame_size.x)
		sprite.set_meta("frame_height", frame_size.y)
		sprite.set_meta("duration", duration)
		sprite.set_meta("remaining", duration)
		sprite.visible = true
		return
