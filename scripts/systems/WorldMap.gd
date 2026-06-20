extends Node2D

const WORLD_BOUNDS := Rect2(-1800.0, -1100.0, 3600.0, 2200.0)

var spawn_regions := {
	&"forest": [Vector2(-1400, -650), Vector2(-1150, 520), Vector2(-650, -850)],
	&"farm": [Vector2(850, -650), Vector2(1350, -350), Vector2(1050, 600)],
	&"camp": [Vector2(-1350, 750), Vector2(-850, 850), Vector2(-1550, 350)],
	&"any": [Vector2(-1400, 0), Vector2(1400, 0), Vector2(0, -900), Vector2(0, 900)]
}

func _ready() -> void:
	_build_boundaries()
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
	# Placeholder fixed map: each color block is a future TileMap art region.
	draw_rect(WORLD_BOUNDS, Color("334a32"))
	draw_rect(Rect2(-1750, -1050, 900, 1200), Color("27442d")) # forest
	draw_rect(Rect2(650, -900, 1000, 1500), Color("6b6730")) # farm
	draw_rect(Rect2(-1650, 500, 950, 500), Color("49352d")) # bandit camp
	draw_rect(Rect2(-380, -260, 760, 520), Color("6f7552")) # village outskirts
	draw_rect(Rect2(-1800, -70, 3600, 140), Color("8a7957")) # main road
	draw_circle(Vector2(0, 0), 115.0, Color("9c8b63"))
	for point in spawn_regions[&"forest"]:
		draw_circle(point, 55.0, Color("183c24"))
	for point in spawn_regions[&"farm"]:
		draw_rect(Rect2(point - Vector2(65, 35), Vector2(130, 70)), Color("91823b"))

func _build_boundaries() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	_add_wall(body, Vector2(0, WORLD_BOUNDS.position.y - 20), Vector2(WORLD_BOUNDS.size.x, 40))
	_add_wall(body, Vector2(0, WORLD_BOUNDS.end.y + 20), Vector2(WORLD_BOUNDS.size.x, 40))
	_add_wall(body, Vector2(WORLD_BOUNDS.position.x - 20, 0), Vector2(40, WORLD_BOUNDS.size.y))
	_add_wall(body, Vector2(WORLD_BOUNDS.end.x + 20, 0), Vector2(40, WORLD_BOUNDS.size.y))

func _add_wall(parent: StaticBody2D, position: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape_node.shape = rectangle
	shape_node.position = position
	parent.add_child(shape_node)
