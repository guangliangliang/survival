extends Area2D

var value: int = 1
var active: bool = false
var target: Node2D
var pool_owner: Node
var attraction_radius: float = 180.0
var attraction_speed: float = 420.0
var anim_time: float = 0.0

const FRAME_COUNT := 4
const ANIMATION_FPS := 8.0
const VISUAL_HEIGHT := 30.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_visual()

func _process(delta: float) -> void:
	if not active:
		return
	anim_time += delta
	_update_visual()
	if not is_instance_valid(target):
		target = GameManager.player
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= attraction_radius:
			global_position = global_position.move_toward(target.global_position, attraction_speed * delta)
		if distance <= 22.0:
			_collect()

func activate(spawn_position: Vector2, exp_value: int, player: Node2D, owner: Node) -> void:
	global_position = spawn_position
	value = exp_value
	target = player
	pool_owner = owner
	active = true
	anim_time = randf() * 0.4
	visible = true
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitoring", false)

func _on_body_entered(body: Node) -> void:
	if active and body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if not active:
		return
	AudioManager.play_sfx_by_key(&"exp_pickup", -4.0)
	GameManager.add_exp(value)
	deactivate()

func _update_visual() -> void:
	var visual := get_node_or_null("Visual") as Sprite2D
	if visual == null or visual.texture == null:
		return
	var frame_width := visual.texture.get_width() / FRAME_COUNT
	var frame_height := visual.texture.get_height()
	var frame := int(anim_time * ANIMATION_FPS) % FRAME_COUNT
	visual.region_rect = Rect2(frame * frame_width, 0, frame_width, frame_height)

func _configure_visual() -> void:
	var visual := get_node_or_null("Visual") as Sprite2D
	if visual == null or visual.texture == null:
		return
	visual.region_enabled = true
	var frame_height := visual.texture.get_height()
	if frame_height > 0:
		var scale_factor := VISUAL_HEIGHT / float(frame_height)
		visual.scale = Vector2.ONE * scale_factor
	_update_visual()
