class_name RunResult
extends Resource

var level_id: StringName = &""
var result: StringName = &""
var elapsed_time: float = 0.0
var kill_count: int = 0
var reached_level: int = 1

static func create(level_data: Resource, end_result: StringName, time: float, kills: int, player_level: int) -> Resource:
	var value := RunResult.new()
	if level_data != null:
		value.level_id = level_data.level_id
	value.result = end_result
	value.elapsed_time = time
	value.kill_count = kills
	value.reached_level = player_level
	return value
