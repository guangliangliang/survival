extends Node2D

const IMPACT_TEXTURE := preload("res://assets/images/effects/fx_bullet_impact.png")
const DEATH_TEXTURE := preload("res://assets/images/effects/fx_death_puff.png")
const ARROW_IMPACT_TEXTURE := preload("res://assets/images/effects/fx_arrow_impact.png")
const HEAL_GLOW_TEXTURE := preload("res://assets/images/effects/fx_heal_glow.png")
const LIGHTNING_BOLT_TEXTURE := preload("res://assets/images/effects/fx_lightning_bolt.png")
const LIGHTNING_IMPACT_TEXTURE := preload("res://assets/images/effects/fx_lightning_impact.png")

@export var pool_size: int = 48
@export var mobile_pool_size: int = 32
@export var mobile_impact_interval: float = 0.04

var effects: Array[Sprite2D] = []
var active_count: int = 0
var mobile_performance_mode: bool = false
var next_mobile_impact_time: float = 0.0

func _ready() -> void:
	mobile_performance_mode = GameManager.is_mobile_performance_profile()
	if mobile_performance_mode:
		pool_size = mini(pool_size, mobile_pool_size)
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
		
		# 支持垂直下落动画 (从 sky 到 ground)
		var start_y: float = sprite.get_meta("start_y", 0.0)
		var target_y: float = sprite.get_meta("target_y", 0.0)
		if start_y != target_y:
			var progress: float = clampf(elapsed / duration, 0.0, 1.0)
			# 使用 ease-out 让下落更自然
			var ease_progress = 1.0 - pow(1.0 - progress, 3.0)
			var current_y = lerp(start_y, target_y, ease_progress)
			sprite.global_position.y = current_y
		
		var follow_target: Node2D = sprite.get_meta("follow_target", null)
		if follow_target != null and is_instance_valid(follow_target):
			sprite.global_position = follow_target.global_position
		sprite.set_meta("remaining", remaining)
		if remaining <= 0.0:
			sprite.visible = false
			active_count -= 1

func play_impact(world_position: Vector2) -> void:
	if not _can_play_mobile_impact():
		return
	_play_strip(IMPACT_TEXTURE, world_position, 4, Vector2i(32, 32), 0.18)

func play_death_puff(world_position: Vector2) -> void:
	_play_strip(DEATH_TEXTURE, world_position, 6, Vector2i(64, 64), 0.42)

func play_arrow_impact(world_position: Vector2) -> void:
	if not _can_play_mobile_impact():
		return
	_play_strip(ARROW_IMPACT_TEXTURE, world_position, 4, Vector2i(192, 512), 0.28, 0.4)

func play_heal_glow(world_position: Vector2) -> void:
	_play_strip(HEAL_GLOW_TEXTURE, world_position, 4, Vector2i(192, 512), 0.72, 0.44)

func play_heal_glow_follow(target: Node2D) -> void:
	_play_strip(HEAL_GLOW_TEXTURE, target.global_position, 4, Vector2i(192, 512), 0.72, 0.44, target)

func play_lightning_bolt(world_position: Vector2, scale: float = 1.0) -> void:
	_play_strip(LIGHTNING_BOLT_TEXTURE, world_position, 1, Vector2i(263, 1536), 0.18, scale)

func play_lightning_impact(world_position: Vector2, scale: float = 1.0) -> void:
	_play_strip(LIGHTNING_IMPACT_TEXTURE, world_position, 4, Vector2i(384, 272), 0.32, scale)

func _can_play_mobile_impact() -> bool:
	if not mobile_performance_mode:
		return true
	var now := float(Time.get_ticks_msec()) * 0.001
	if now < next_mobile_impact_time:
		return false
	next_mobile_impact_time = now + mobile_impact_interval
	return true

func _play_strip_vertical_drop(texture: Texture2D, start_pos: Vector2, target_pos: Vector2, frames: int, frame_size: Vector2i, duration: float, scale: float = 1.0) -> void:
	for sprite in effects:
		if sprite.visible:
			continue
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_size.x, frame_size.y)
		sprite.global_position = start_pos
		sprite.scale = Vector2(scale, scale)
		sprite.modulate = Color.WHITE
		sprite.set_meta("frames", frames)
		sprite.set_meta("frame_width", frame_size.x)
		sprite.set_meta("frame_height", frame_size.y)
		sprite.set_meta("duration", duration)
		sprite.set_meta("remaining", duration)
		sprite.set_meta("start_y", start_pos.y)
		sprite.set_meta("target_y", target_pos.y)
		sprite.set_meta("follow_target", null)
		sprite.visible = true
		active_count += 1
		return

func play_lightning_strike(world_position: Vector2, bolt_scale: float = 0.12, impact_scale: float = 0.3) -> void:
	# 闪电从天上 300px 处落下，0.12s 后落地消失
	var bolt_start = world_position + Vector2(0, -300)
	_play_strip_vertical_drop(LIGHTNING_BOLT_TEXTURE, bolt_start, world_position, 1, Vector2i(263, 1536), 0.12, bolt_scale)
	# 让 impact 等 bolt 落完再触发，避免错位
	await get_tree().create_timer(0.12).timeout
	play_lightning_impact(world_position, impact_scale)

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
		sprite.set_meta("start_y", 0.0)
		sprite.set_meta("target_y", 0.0)
		if follow_target != null:
			sprite.set_meta("follow_target", follow_target)
		else:
			sprite.set_meta("follow_target", null)
		sprite.visible = true
		active_count += 1
		return
