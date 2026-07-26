extends Node2D

const DEFAULT_WORLD_BOUNDS := Rect2(-1800.0, -1100.0, 3600.0, 2200.0)
const MAP_TEXTURES := {
	&"frontier_desert": preload("res://assets/images/maps/map_frontier_desert_plain.png"),
	&"frontier_grassland": preload("res://assets/images/maps/map_frontier_grassland_plain.png"),
	&"frontier_red_earth": preload("res://assets/images/maps/map_frontier_red_earth_plain.png")
}
const OBSTACLE_TEXTURES := {
	&"crate_double": preload("res://assets/images/obstacles/obstacle_crate_double_stack.png"),
	&"crate_row": preload("res://assets/images/obstacles/obstacle_crate_horizontal_row.png"),
	&"crate_single": preload("res://assets/images/obstacles/obstacle_crate_single.png"),
	&"fence_damaged": preload("res://assets/images/obstacles/obstacle_fence_metal_damaged.png"),
	&"fence_long": preload("res://assets/images/obstacles/obstacle_fence_metal_long.png"),
	&"fence_short": preload("res://assets/images/obstacles/obstacle_fence_metal_short.png"),
	&"rock_long": preload("res://assets/images/obstacles/obstacle_rock_long.png"),
	&"rock_medium": preload("res://assets/images/obstacles/obstacle_rock_medium_oval.png"),
	&"rock_small": preload("res://assets/images/obstacles/obstacle_rock_small_round.png"),
	&"sandbag_l": preload("res://assets/images/obstacles/obstacle_sandbag_l_shape.png"),
	&"sandbag_long": preload("res://assets/images/obstacles/obstacle_sandbag_long.png"),
	&"sandbag_short": preload("res://assets/images/obstacles/obstacle_sandbag_short.png")
}
const FRONTIER_OBSTACLES := {
	&"frontier_desert": [
		{"texture": &"rock_long", "position": Vector2(-1850, -1040), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"rock_medium", "position": Vector2(-1470, -880), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_small", "position": Vector2(-1980, -680), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"rock_medium", "position": Vector2(1820, -1040), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_long", "position": Vector2(1460, -860), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"rock_small", "position": Vector2(1980, -670), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"rock_long", "position": Vector2(-1830, 1040), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"rock_small", "position": Vector2(-1460, 870), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"crate_single", "position": Vector2(-1970, 690), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"rock_medium", "position": Vector2(1830, 1040), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_long", "position": Vector2(1470, 860), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"sandbag_short", "position": Vector2(1970, 680), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"rock_small", "position": Vector2(-360, -1200), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"rock_medium", "position": Vector2(420, -1170), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_medium", "position": Vector2(-420, 1190), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"crate_single", "position": Vector2(360, 1200), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"rock_long", "position": Vector2(-2300, -150), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"rock_medium", "position": Vector2(-2250, 220), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_long", "position": Vector2(2300, 160), "scale": 0.18, "collision": Vector2(205, 74)},
		{"texture": &"rock_medium", "position": Vector2(2250, -220), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_small", "position": Vector2(720, -650), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"rock_medium", "position": Vector2(-760, 600), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"rock_small", "position": Vector2(-670, -700), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"crate_single", "position": Vector2(730, 660), "scale": 0.22, "collision": Vector2(92, 92)}
	],
	&"frontier_grassland": [
		{"texture": &"fence_long", "position": Vector2(-1850, -1040), "scale": 0.19, "collision": Vector2(215, 52), "collision_offset": Vector2(0, 55)},
		{"texture": &"crate_double", "position": Vector2(-1470, -880), "scale": 0.22, "collision": Vector2(78, 80), "collision_offset": Vector2(0, 48)},
		{"texture": &"rock_small", "position": Vector2(-1980, -680), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"fence_short", "position": Vector2(1820, -1040), "scale": 0.18, "collision": Vector2(165, 50), "collision_offset": Vector2(0, 60)},
		{"texture": &"crate_single", "position": Vector2(1460, -860), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"crate_double", "position": Vector2(1980, -670), "scale": 0.22, "collision": Vector2(78, 80), "collision_offset": Vector2(0, 48)},
		{"texture": &"fence_long", "position": Vector2(-1830, 1040), "scale": 0.19, "collision": Vector2(215, 52), "collision_offset": Vector2(0, 55)},
		{"texture": &"crate_single", "position": Vector2(-1460, 870), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"rock_medium", "position": Vector2(-1970, 690), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"fence_short", "position": Vector2(1830, 1040), "scale": 0.18, "collision": Vector2(165, 50), "collision_offset": Vector2(0, 60)},
		{"texture": &"crate_double", "position": Vector2(1470, 860), "scale": 0.22, "collision": Vector2(78, 80), "collision_offset": Vector2(0, 48)},
		{"texture": &"crate_single", "position": Vector2(1970, 680), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"fence_long", "position": Vector2(-360, -1190), "scale": 0.19, "collision": Vector2(215, 52), "collision_offset": Vector2(0, 55)},
		{"texture": &"crate_single", "position": Vector2(420, -1200), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"crate_double", "position": Vector2(-420, 1190), "scale": 0.22, "collision": Vector2(78, 80), "collision_offset": Vector2(0, 48)},
		{"texture": &"fence_short", "position": Vector2(360, 1200), "scale": 0.18, "collision": Vector2(165, 50), "collision_offset": Vector2(0, 60)},
		{"texture": &"fence_long", "position": Vector2(-2300, -150), "scale": 0.19, "collision": Vector2(215, 52), "collision_offset": Vector2(0, 55)},
		{"texture": &"rock_medium", "position": Vector2(-2250, 220), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"fence_long", "position": Vector2(2300, 160), "scale": 0.19, "collision": Vector2(215, 52), "collision_offset": Vector2(0, 55)},
		{"texture": &"crate_single", "position": Vector2(2250, -220), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"crate_double", "position": Vector2(720, -650), "scale": 0.22, "collision": Vector2(78, 80), "collision_offset": Vector2(0, 48)},
		{"texture": &"fence_short", "position": Vector2(-760, 600), "scale": 0.18, "collision": Vector2(165, 50), "collision_offset": Vector2(0, 60)},
		{"texture": &"crate_single", "position": Vector2(-670, -700), "scale": 0.22, "collision": Vector2(92, 92)},
		{"texture": &"rock_small", "position": Vector2(730, 660), "scale": 0.28, "collision": Vector2(82, 62)}
	],
	&"frontier_red_earth": [
		{"texture": &"sandbag_long", "position": Vector2(-1850, -1040), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"sandbag_short", "position": Vector2(-1470, -880), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"rock_small", "position": Vector2(-1980, -680), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"sandbag_l", "position": Vector2(1820, -1040), "scale": 0.20, "collisions": [
			{"size": Vector2(260, 76), "offset": Vector2(42, 62)},
			{"size": Vector2(76, 210), "offset": Vector2(-105, -16)}
		]},
		{"texture": &"sandbag_long", "position": Vector2(1460, -860), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"fence_damaged", "position": Vector2(1980, -670), "scale": 0.19, "collision": Vector2(255, 55), "collision_offset": Vector2(0, 80)},
		{"texture": &"sandbag_long", "position": Vector2(-1830, 1040), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"fence_damaged", "position": Vector2(-1460, 870), "scale": 0.19, "collision": Vector2(255, 55), "collision_offset": Vector2(0, 80)},
		{"texture": &"crate_row", "position": Vector2(-1970, 690), "scale": 0.15, "collision": Vector2(225, 95), "collision_offset": Vector2(0, 50)},
		{"texture": &"sandbag_l", "position": Vector2(1830, 1040), "scale": 0.20, "collisions": [
			{"size": Vector2(260, 76), "offset": Vector2(42, 62)},
			{"size": Vector2(76, 210), "offset": Vector2(-105, -16)}
		]},
		{"texture": &"sandbag_short", "position": Vector2(1470, 860), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"sandbag_long", "position": Vector2(1970, 680), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"sandbag_long", "position": Vector2(-360, -1190), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"sandbag_short", "position": Vector2(420, -1200), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"sandbag_short", "position": Vector2(-420, 1190), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"sandbag_long", "position": Vector2(360, 1200), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"fence_damaged", "position": Vector2(-2300, -150), "scale": 0.19, "collision": Vector2(255, 55), "collision_offset": Vector2(0, 80)},
		{"texture": &"rock_medium", "position": Vector2(-2250, 220), "scale": 0.19, "collision": Vector2(150, 100)},
		{"texture": &"fence_damaged", "position": Vector2(2300, 160), "scale": 0.19, "collision": Vector2(255, 55), "collision_offset": Vector2(0, 80)},
		{"texture": &"crate_row", "position": Vector2(2250, -220), "scale": 0.15, "collision": Vector2(225, 95), "collision_offset": Vector2(0, 50)},
		{"texture": &"sandbag_short", "position": Vector2(720, -650), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)},
		{"texture": &"sandbag_long", "position": Vector2(-760, 600), "scale": 0.21, "collision": Vector2(255, 80), "collision_offset": Vector2(0, 55)},
		{"texture": &"rock_small", "position": Vector2(-670, -700), "scale": 0.28, "collision": Vector2(82, 62)},
		{"texture": &"sandbag_short", "position": Vector2(730, 660), "scale": 0.19, "collision": Vector2(185, 68), "collision_offset": Vector2(0, 40)}
	]
}

var spawn_regions := {
	&"forest": [Vector2(-1400, -650), Vector2(-1150, 520), Vector2(-650, -850)],
	&"farm": [Vector2(850, -650), Vector2(1350, -350), Vector2(1050, 600)],
	&"camp": [Vector2(-1350, 750), Vector2(-850, 850), Vector2(-1550, 350)],
	&"any": [Vector2(-1400, 0), Vector2(1400, 0), Vector2(0, -900), Vector2(0, 900)]
}
var map_variant: StringName = &"frontier_desert"
var current_world_bounds := DEFAULT_WORLD_BOUNDS
var obstacle_rects: Array[Rect2] = []
var obstacle_block_rects: Array[Rect2] = []

func _ready() -> void:
	_refresh_world_bounds()
	_build_boundaries()
	_build_obstacles()
	queue_redraw()

func configure(level_data: Resource) -> void:
	if level_data != null:
		map_variant = level_data.map_variant
	_refresh_world_bounds()
	_build_boundaries()
	_build_obstacles()
	queue_redraw()

func get_world_bounds() -> Rect2:
	return current_world_bounds

func get_obstacle_block_rects() -> Array[Rect2]:
	return obstacle_block_rects.duplicate()

func get_spawn_position(region: StringName, avoid_position: Vector2) -> Vector2:
	var points: Array = spawn_regions.get(region, spawn_regions[&"any"])
	var candidates := points.filter(func(point: Vector2): return point.distance_to(avoid_position) > 520.0)
	if candidates.is_empty():
		candidates = points
	var center: Vector2 = candidates.pick_random()
	for attempt in 12:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(80.0, 260.0)
		var candidate := (center + offset).clamp(current_world_bounds.position + Vector2(40, 40), current_world_bounds.end - Vector2(40, 40))
		if _is_spawn_position_open(candidate):
			return candidate
	return center.clamp(current_world_bounds.position + Vector2(40, 40), current_world_bounds.end - Vector2(40, 40))

func _is_spawn_position_open(position: Vector2) -> bool:
	for rect in obstacle_block_rects:
		if rect.grow(96.0).has_point(position):
			return false
	return true

func _draw() -> void:
	var texture := _get_map_texture()
	if texture != null:
		draw_texture_rect(texture, current_world_bounds, false)
	else:
		_draw_fallback_map()
	for rect in obstacle_rects:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.28))

func _get_map_texture() -> Texture2D:
	return MAP_TEXTURES.get(map_variant, MAP_TEXTURES[&"frontier_desert"])

func _refresh_world_bounds() -> void:
	var texture := _get_map_texture()
	if texture == null:
		current_world_bounds = DEFAULT_WORLD_BOUNDS
		return
	var texture_size := texture.get_size()
	current_world_bounds = Rect2(texture_size * -0.5, texture_size)

func _draw_fallback_map() -> void:
	match map_variant:
		&"forest":
			draw_rect(current_world_bounds, Color("172f24"))
			draw_rect(Rect2(-260, -1100, 520, 2200), Color("40543a"))
			for point in spawn_regions[&"forest"] + spawn_regions[&"any"]:
				draw_circle(point, 90.0, Color("0f241b"))
		&"camp":
			draw_rect(current_world_bounds, Color("3c3028"))
			draw_rect(Rect2(-1800, -100, 3600, 200), Color("77604b"))
			draw_rect(Rect2(-1500, 420, 1100, 560), Color("542e27"))
			for point in spawn_regions[&"camp"]:
				draw_circle(point, 75.0, Color("241917"))
		_:
			draw_rect(current_world_bounds, Color("334a32"))
			draw_rect(Rect2(-1750, -1050, 900, 1200), Color("27442d"))
			draw_rect(Rect2(650, -900, 1000, 1500), Color("6b6730"))
			draw_rect(Rect2(-380, -260, 760, 520), Color("6f7552"))
			draw_rect(Rect2(-1800, -70, 3600, 140), Color("8a7957"))
			draw_circle(Vector2.ZERO, 115.0, Color("9c8b63"))

func _build_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "Boundaries"
	body.collision_layer = 1
	body.collision_mask = 1
	var previous := get_node_or_null("Boundaries")
	if previous != null:
		previous.free()
	add_child(body)
	_add_wall(body, Vector2(0, current_world_bounds.position.y - 20), Vector2(current_world_bounds.size.x, 40))
	_add_wall(body, Vector2(0, current_world_bounds.end.y + 20), Vector2(current_world_bounds.size.x, 40))
	_add_wall(body, Vector2(current_world_bounds.position.x - 20, 0), Vector2(40, current_world_bounds.size.y))
	_add_wall(body, Vector2(current_world_bounds.end.x + 20, 0), Vector2(40, current_world_bounds.size.y))

func _build_obstacles() -> void:
	var previous := get_node_or_null("Obstacles")
	if previous != null:
		previous.free()
	obstacle_rects.clear()
	obstacle_block_rects.clear()
	match map_variant:
		&"frontier_desert", &"frontier_grassland", &"frontier_red_earth":
			obstacle_rects = []
		&"forest":
			obstacle_rects = [Rect2(-900, -500, 260, 720), Rect2(620, -140, 300, 740), Rect2(-350, 520, 700, 180)]
		&"camp":
			obstacle_rects = [Rect2(-1050, -650, 360, 180), Rect2(520, -700, 480, 190), Rect2(-150, 450, 600, 180)]
		_:
			obstacle_rects = [Rect2(-620, -720, 240, 150), Rect2(720, 430, 300, 170)]
	obstacle_block_rects = obstacle_rects.duplicate()
	var body := StaticBody2D.new()
	body.name = "Obstacles"
	body.z_index = 0
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	for obstacle_data in FRONTIER_OBSTACLES.get(map_variant, []):
		_add_visual_obstacle(body, obstacle_data)
	for rect in obstacle_rects:
		_add_wall(body, rect.get_center(), rect.size)

func _add_visual_obstacle(parent: StaticBody2D, obstacle_data: Dictionary) -> void:
	var texture: Texture2D = OBSTACLE_TEXTURES.get(obstacle_data.get("texture", &""))
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = obstacle_data.get("position", Vector2.ZERO)
	sprite.scale = Vector2.ONE * float(obstacle_data.get("scale", 1.0))
	parent.add_child(sprite)
	if obstacle_data.has("collisions"):
		for collision_data in obstacle_data["collisions"]:
			_add_obstacle_collision(parent, sprite.position, collision_data["size"], collision_data.get("offset", Vector2.ZERO))
	else:
		_add_obstacle_collision(parent, sprite.position, obstacle_data["collision"], obstacle_data.get("collision_offset", Vector2.ZERO))

func _add_obstacle_collision(parent: StaticBody2D, center: Vector2, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape_node.shape = rectangle
	shape_node.position = center + offset
	parent.add_child(shape_node)
	obstacle_block_rects.append(Rect2(shape_node.position - size * 0.5, size))

func _add_wall(parent: StaticBody2D, position: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape_node.shape = rectangle
	shape_node.position = position
	parent.add_child(shape_node)
