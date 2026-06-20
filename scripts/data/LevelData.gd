class_name LevelData
extends Resource

@export var level_id: StringName = &"village_outskirts"
@export var title: String = "村庄外围"
@export_multiline var description: String = "清理村庄周边的野兽。"
@export var duration: float = 360.0
@export var boss_spawn_time: float = 300.0
@export var map_variant: StringName = &"village"
@export var enemy_catalog: Array[Resource] = []
@export var boss_data: Resource
@export var spawn_interval: float = 1.4
@export var active_enemy_limit: int = 120
@export var difficulty_multiplier: float = 1.0
@export var accent_color: Color = Color("b9a35b")

func formatted_duration() -> String:
	return "%d 分钟" % int(duration / 60.0)
