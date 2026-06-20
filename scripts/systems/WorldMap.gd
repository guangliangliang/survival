extends Node2D

const WORLD_BOUNDS := Rect2(-1800.0, -1100.0, 3600.0, 2200.0)

var spawn_regions := {
	&"forest": [Vector2(-1400, -650), Vector2(-1150, 520), Vector2(-650, -850)],
	&"farm": [Vector2(850, -650), Vector2(1350, -350), Vector2(1050, 600)],
	&"camp": [Vector2(-1350, 750), Vector2(-850, 850), Vector2(-1550, 350)],
	&"any": [Vector2(-1400, 0), Vector2(1400, 0), Vector2(0, -900), Vector2(0, 900)]
}
var map_variant: StringName = &"village"
var obstacle_rects: Array[Rect2] = []

func _ready() -> void:
	_build_boundaries()
	_build_obstacles()
	queue_redraw()

func configure(level_data: Resource) -> void:
	if level_data != null:
		map_variant = level_data.map_variant
	_build_obstacles()
	queue_redraw()

func get_world_bounds() -> Rect2:
	return WORLD_BOUNDS

func get_spawn_position(region: StringName, avoid_position: Vector2) -> Vector2:
	var points: Array = spawn_regions.get(region, spawn_regions[&"any"])
	var candidates := points.filter(func(point: Vector2): return point.distance_to(avoid_position) > 520.0)
	if candidates.is_empty():
		candidates = points
	var center: Vector2 = candidates.pick_random()
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(80.0, 260.0)
	return (center + offset).clamp(WORLD_BOUNDS.position + Vector2(40, 40), WORLD_BOUNDS.end - Vector2(40, 40))

func _draw() -> void:
	match map_variant:
		&"forest":
			draw_rect(WORLD_BOUNDS, Color("172f24"))
			draw_rect(Rect2(-260, -1100, 520, 2200), Color("40543a"))
			for point in spawn_regions[&"forest"] + spawn_regions[&"any"]:
				draw_circle(point, 90.0, Color("0f241b"))
		&"camp":
			draw_rect(WORLD_BOUNDS, Color("3c3028"))
			draw_rect(Rect2(-1800, -100, 3600, 200), Color("77604b"))
			draw_rect(Rect2(-1500, 420, 1100, 560), Color("542e27"))
			for point in spawn_regions[&"camp"]:
				draw_circle(point, 75.0, Color("241917"))
		_:
			draw_rect(WORLD_BOUNDS, Color("334a32"))
			draw_rect(Rect2(-1750, -1050, 900, 1200), Color("27442d"))
			draw_rect(Rect2(650, -900, 1000, 1500), Color("6b6730"))
			draw_rect(Rect2(-380, -260, 760, 520), Color("6f7552"))
			draw_rect(Rect2(-1800, -70, 3600, 140), Color("8a7957"))
			draw_circle(Vector2.ZERO, 115.0, Color("9c8b63"))
	for rect in obstacle_rects:
		draw_rect(rect, Color("18251c") if map_variant == &"forest" else Color("4d3527"))

func _build_boundaries() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	_add_wall(body, Vector2(0, WORLD_BOUNDS.position.y - 20), Vector2(WORLD_BOUNDS.size.x, 40))
	_add_wall(body, Vector2(0, WORLD_BOUNDS.end.y + 20), Vector2(WORLD_BOUNDS.size.x, 40))
	_add_wall(body, Vector2(WORLD_BOUNDS.position.x - 20, 0), Vector2(40, WORLD_BOUNDS.size.y))
	_add_wall(body, Vector2(WORLD_BOUNDS.end.x + 20, 0), Vector2(40, WORLD_BOUNDS.size.y))

func _build_obstacles() -> void:
	var previous := get_node_or_null("Obstacles")
	if previous != null:
		previous.queue_free()
	obstacle_rects.clear()
	match map_variant:
		&"forest":
			obstacle_rects = [Rect2(-900, -500, 260, 720), Rect2(620, -140, 300, 740), Rect2(-350, 520, 700, 180)]
		&"camp":
			obstacle_rects = [Rect2(-1050, -650, 360, 180), Rect2(520, -700, 480, 190), Rect2(-150, 450, 600, 180)]
		_:
			obstacle_rects = [Rect2(-620, -720, 240, 150), Rect2(720, 430, 300, 170)]
	var body := StaticBody2D.new()
	body.name = "Obstacles"
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	for rect in obstacle_rects:
		_add_wall(body, rect.get_center(), rect.size)

func _add_wall(parent: StaticBody2D, position: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape_node.shape = rectangle
	shape_node.position = position
	parent.add_child(shape_node)
