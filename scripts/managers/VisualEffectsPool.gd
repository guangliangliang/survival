extends Node2D

const IMPACT_TEXTURE := preload("res://assets/images/effects/fx_bullet_impact.png")
const DEATH_TEXTURE := preload("res://assets/images/effects/fx_death_puff.png")
const ARROW_IMPACT_TEXTURE := preload("res://assets/images/effects/fx_arrow_impact.png")
const HEAL_GLOW_TEXTURE := preload("res://assets/images/effects/fx_heal_glow.png")

@export var pool_size: int = 48

var effects: Array[Sprite2D] = []
var active_count: int = 0

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
	if active_count <= 0:
		return
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
		var follow_target: Node2D = sprite.get_meta("follow_target", null)
		if follow_target != null and is_instance_valid(follow_target):
			sprite.global_position = follow_target.global_position
		sprite.set_meta("remaining", remaining)
		if remaining <= 0.0:
			sprite.visible = false
			active_count -= 1

func play_impact(world_position: Vector2) -> void:
	_play_strip(IMPACT_TEXTURE, world_position, 4, Vector2i(32, 32), 0.18)

func play_death_puff(world_position: Vector2) -> void:
	_play_strip(DEATH_TEXTURE, world_position, 6, Vector2i(64, 64), 0.42)

func play_arrow_impact(world_position: Vector2) -> void:
	_play_strip(ARROW_IMPACT_TEXTURE, world_position, 4, Vector2i(192, 512), 0.28, 0.4)

func play_heal_glow(world_position: Vector2) -> void:
	_play_strip(HEAL_GLOW_TEXTURE, world_position, 4, Vector2i(192, 512), 0.72, 0.44)

func play_heal_glow_follow(target: Node2D) -> void:
	_play_strip(HEAL_GLOW_TEXTURE, target.global_position, 4, Vector2i(192, 512), 0.72, 0.44, target)

func _play_strip(texture: Texture2D, world_position: Vector2, frames: int, frame_size: Vector2i, duration: float, scale: float = 1.0, follow_target: Node2D = null) -> void:
	for sprite in effects:
		if sprite.visible:
			continue
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_size.x, frame_size.y)
		sprite.global_position = world_position
		sprite.scale = Vector2(scale, scale)
		sprite.modulate = Color.WHITE
		sprite.set_meta("frames", frames)
		sprite.set_meta("frame_width", frame_size.x)
		sprite.set_meta("frame_height", frame_size.y)
		sprite.set_meta("duration", duration)
		sprite.set_meta("remaining", duration)
		if follow_target != null:
			sprite.set_meta("follow_target", follow_target)
		else:
			sprite.set_meta("follow_target", null)
		sprite.visible = true
		active_count += 1
		return
