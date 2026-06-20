class_name LevelPreview
extends Control

var map_variant: StringName = &"village"
var accent_color := Color("b9a35b")

func configure(level_data: Resource) -> void:
	map_variant = level_data.map_variant
	accent_color = level_data.accent_color
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, accent_color.darkened(0.48))
	match map_variant:
		&"forest":
			_draw_forest(bounds)
		&"camp":
			_draw_camp(bounds)
		_:
			_draw_village(bounds)
	draw_rect(bounds.grow(-5.0), accent_color.lightened(0.18), false, 4.0)

func _draw_village(bounds: Rect2) -> void:
	draw_rect(Rect2(0, bounds.size.y * 0.45, bounds.size.x, 34), Color("9b855b"))
	draw_rect(Rect2(bounds.size.x * 0.42, 0, 38, bounds.size.y), Color("89764f"))
	draw_rect(Rect2(34, 25, 88, 54), Color("5f7040"))
	draw_rect(Rect2(bounds.size.x - 126, 74, 90, 58), Color("8a7938"))
	draw_circle(bounds.size * 0.5, 24.0, Color("d2b56c"))

func _draw_forest(bounds: Rect2) -> void:
	draw_rect(Rect2(bounds.size.x * 0.4, 0, bounds.size.x * 0.2, bounds.size.y), Color("526447"))
	for point in [Vector2(40, 36), Vector2(100, 90), Vector2(155, 38), Vector2(240, 105), Vector2(305, 45)]:
		draw_circle(point, 25.0, Color("173823"))
		draw_circle(point - Vector2(0, 7), 17.0, Color("2b5b31"))

func _draw_camp(bounds: Rect2) -> void:
	draw_rect(Rect2(0, bounds.size.y * 0.46, bounds.size.x, 32), Color("8a6b4e"))
	for origin in [Vector2(58, 42), Vector2(210, 85), Vector2(300, 34)]:
		var tent := PackedVector2Array([origin + Vector2(-28, 24), origin + Vector2(0, -24), origin + Vector2(28, 24)])
		draw_colored_polygon(tent, Color("7f3f30"))
		draw_line(origin + Vector2(0, -24), origin + Vector2(0, 24), Color("d6b276"), 3.0)
	draw_circle(Vector2(150, 112), 13.0, Color("ef9b32"))
