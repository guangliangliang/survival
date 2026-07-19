class_name LevelPreview
extends Control

const PREVIEW_TEXTURES := {
	&"frontier_desert": preload("res://assets/images/maps/map_frontier_desert_plain.png"),
	&"frontier_grassland": preload("res://assets/images/maps/map_frontier_grassland_plain.png"),
	&"frontier_red_earth": preload("res://assets/images/maps/map_frontier_red_earth_plain.png")
}

var map_variant: StringName = &"frontier_desert"
var accent_color := Color("b9a35b")

func configure(level_data: Resource) -> void:
	map_variant = level_data.map_variant
	accent_color = level_data.accent_color
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	var texture: Texture2D = PREVIEW_TEXTURES.get(map_variant, PREVIEW_TEXTURES[&"frontier_desert"])
	if texture != null:
		draw_texture_rect(texture, bounds, false)
		draw_rect(bounds, Color(0.0, 0.0, 0.0, 0.18))
	else:
		draw_rect(bounds, accent_color.darkened(0.48))
	draw_rect(bounds.grow(-5.0), accent_color.lightened(0.18), false, 4.0)
