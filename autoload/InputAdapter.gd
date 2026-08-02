extends Node

var virtual_move: Vector2 = Vector2.ZERO
var virtual_attack_requested: bool = false
var virtual_dash_requested: bool = false
var virtual_scatter_requested: bool = false
var virtual_sword_rain_requested: bool = false
var virtual_sword_rain_aiming: bool = false
var virtual_sword_rain_aim_offset: Vector2 = Vector2.ZERO
var virtual_sword_rain_cast_requested: bool = false
var virtual_lightning_storm_requested: bool = false
var virtual_lightning_storm_aiming: bool = false
var virtual_lightning_storm_aim_offset: Vector2 = Vector2.ZERO
var virtual_lightning_storm_cast_requested: bool = false
var virtual_heal_requested: bool = false
var attack_held: bool = false
var auto_attack_enabled: bool = true
var dash_cooldown_remaining: float = 0.0
var dash_cooldown_duration: float = 10.0
var scatter_cooldown_remaining: float = 0.0
var scatter_cooldown_duration: float = 9.0
var sword_rain_cooldown_remaining: float = 0.0
var sword_rain_cooldown_duration: float = 10.0
var lightning_storm_cooldown_remaining: float = 0.0
var lightning_storm_cooldown_duration: float = 11.0
var heal_cooldown_remaining: float = 0.0
var heal_cooldown_duration: float = 15.0

func get_move_vector() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if keyboard.length_squared() > 0.0:
		return keyboard.normalized()
	return virtual_move.limit_length(1.0)

func consume_attack_requested() -> bool:
	var requested := virtual_attack_requested or Input.is_action_pressed("attack")
	virtual_attack_requested = false
	return requested

func consume_dash_requested() -> bool:
	var requested := virtual_dash_requested
	virtual_dash_requested = false
	return requested

func consume_scatter_requested() -> bool:
	var requested := virtual_scatter_requested
	virtual_scatter_requested = false
	return requested

func consume_sword_rain_requested() -> bool:
	var requested := virtual_sword_rain_requested
	virtual_sword_rain_requested = false
	return requested

func consume_lightning_storm_requested() -> bool:
	var requested := virtual_lightning_storm_requested
	virtual_lightning_storm_requested = false
	return requested

func consume_heal_requested() -> bool:
	var requested := virtual_heal_requested
	virtual_heal_requested = false
	return requested

func set_virtual_move(value: Vector2) -> void:
	virtual_move = value.limit_length(1.0)

func clear_virtual_move() -> void:
	virtual_move = Vector2.ZERO

func request_virtual_attack() -> void:
	virtual_attack_requested = true

func clear_virtual_attack() -> void:
	virtual_attack_requested = false

func request_virtual_dash() -> void:
	if dash_cooldown_remaining <= 0.0:
		virtual_dash_requested = true

func clear_virtual_dash() -> void:
	virtual_dash_requested = false

func request_virtual_scatter() -> void:
	if scatter_cooldown_remaining <= 0.0:
		virtual_scatter_requested = true

func clear_virtual_scatter() -> void:
	virtual_scatter_requested = false

func request_virtual_sword_rain() -> void:
	if sword_rain_cooldown_remaining <= 0.0:
		virtual_sword_rain_requested = true

func request_virtual_lightning_storm() -> void:
	if lightning_storm_cooldown_remaining <= 0.0:
		virtual_lightning_storm_requested = true

func clear_virtual_sword_rain() -> void:
	virtual_sword_rain_requested = false
	virtual_sword_rain_aiming = false
	virtual_sword_rain_aim_offset = Vector2.ZERO
	virtual_sword_rain_cast_requested = false

func clear_virtual_lightning_storm() -> void:
	virtual_lightning_storm_requested = false
	virtual_lightning_storm_aiming = false
	virtual_lightning_storm_aim_offset = Vector2.ZERO
	virtual_lightning_storm_cast_requested = false

func begin_virtual_sword_rain_aim() -> void:
	if sword_rain_cooldown_remaining <= 0.0:
		virtual_sword_rain_aiming = true
		virtual_sword_rain_aim_offset = Vector2.ZERO
		virtual_sword_rain_cast_requested = false

func begin_virtual_lightning_storm_aim() -> void:
	if lightning_storm_cooldown_remaining <= 0.0:
		virtual_lightning_storm_aiming = true
		virtual_lightning_storm_aim_offset = Vector2.ZERO
		virtual_lightning_storm_cast_requested = false

func set_virtual_sword_rain_aim_offset(offset: Vector2) -> void:
	if virtual_sword_rain_aiming:
		virtual_sword_rain_aim_offset = offset

func set_virtual_lightning_storm_aim_offset(offset: Vector2) -> void:
	if virtual_lightning_storm_aiming:
		virtual_lightning_storm_aim_offset = offset

func confirm_virtual_sword_rain_aim() -> void:
	if virtual_sword_rain_aiming:
		virtual_sword_rain_aiming = false
		virtual_sword_rain_cast_requested = true

func confirm_virtual_lightning_storm_aim() -> void:
	if virtual_lightning_storm_aiming:
		virtual_lightning_storm_aiming = false
		virtual_lightning_storm_cast_requested = true

func cancel_virtual_sword_rain_aim() -> void:
	virtual_sword_rain_aiming = false
	virtual_sword_rain_cast_requested = false

func cancel_virtual_lightning_storm_aim() -> void:
	virtual_lightning_storm_aiming = false
	virtual_lightning_storm_cast_requested = false

func is_virtual_sword_rain_aiming() -> bool:
	return virtual_sword_rain_aiming

func is_virtual_lightning_storm_aiming() -> bool:
	return virtual_lightning_storm_aiming

func get_virtual_sword_rain_aim_offset() -> Vector2:
	return virtual_sword_rain_aim_offset

func get_virtual_lightning_storm_aim_offset() -> Vector2:
	return virtual_lightning_storm_aim_offset

func consume_virtual_sword_rain_cast() -> bool:
	var requested := virtual_sword_rain_cast_requested
	virtual_sword_rain_cast_requested = false
	return requested

func consume_virtual_lightning_storm_cast() -> bool:
	var requested := virtual_lightning_storm_cast_requested
	virtual_lightning_storm_cast_requested = false
	return requested

func request_virtual_heal() -> void:
	if heal_cooldown_remaining <= 0.0:
		virtual_heal_requested = true

func clear_virtual_heal() -> void:
	virtual_heal_requested = false

func set_dash_cooldown_remaining(value: float) -> void:
	dash_cooldown_remaining = maxf(0.0, value)

func set_dash_cooldown(remaining: float, duration: float) -> void:
	dash_cooldown_remaining = maxf(0.0, remaining)
	dash_cooldown_duration = maxf(0.01, duration)

func get_dash_cooldown_remaining() -> float:
	return dash_cooldown_remaining

func get_dash_cooldown_duration() -> float:
	return dash_cooldown_duration

func get_dash_cooldown_ratio() -> float:
	return clampf(dash_cooldown_remaining / dash_cooldown_duration, 0.0, 1.0)

func is_dash_ready() -> bool:
	return dash_cooldown_remaining <= 0.0

func reset_dash_cooldown() -> void:
	dash_cooldown_remaining = 0.0
	clear_virtual_dash()

func set_scatter_cooldown(remaining: float, duration: float) -> void:
	scatter_cooldown_remaining = maxf(0.0, remaining)
	scatter_cooldown_duration = maxf(0.01, duration)

func get_scatter_cooldown_remaining() -> float:
	return scatter_cooldown_remaining

func get_scatter_cooldown_duration() -> float:
	return scatter_cooldown_duration

func get_scatter_cooldown_ratio() -> float:
	return clampf(scatter_cooldown_remaining / scatter_cooldown_duration, 0.0, 1.0)

func is_scatter_ready() -> bool:
	return scatter_cooldown_remaining <= 0.0

func reset_scatter_cooldown() -> void:
	scatter_cooldown_remaining = 0.0
	clear_virtual_scatter()

func set_sword_rain_cooldown(remaining: float, duration: float) -> void:
	sword_rain_cooldown_remaining = maxf(0.0, remaining)
	sword_rain_cooldown_duration = maxf(0.01, duration)

func get_sword_rain_cooldown_remaining() -> float:
	return sword_rain_cooldown_remaining

func get_sword_rain_cooldown_duration() -> float:
	return sword_rain_cooldown_duration

func get_sword_rain_cooldown_ratio() -> float:
	return clampf(sword_rain_cooldown_remaining / sword_rain_cooldown_duration, 0.0, 1.0)

func is_sword_rain_ready() -> bool:
	return sword_rain_cooldown_remaining <= 0.0

func reset_sword_rain_cooldown() -> void:
	sword_rain_cooldown_remaining = 0.0
	clear_virtual_sword_rain()

func set_lightning_storm_cooldown(remaining: float, duration: float) -> void:
	lightning_storm_cooldown_remaining = maxf(0.0, remaining)
	lightning_storm_cooldown_duration = maxf(0.01, duration)

func get_lightning_storm_cooldown_remaining() -> float:
	return lightning_storm_cooldown_remaining

func get_lightning_storm_cooldown_duration() -> float:
	return lightning_storm_cooldown_duration

func get_lightning_storm_cooldown_ratio() -> float:
	return clampf(lightning_storm_cooldown_remaining / lightning_storm_cooldown_duration, 0.0, 1.0)

func is_lightning_storm_ready() -> bool:
	return lightning_storm_cooldown_remaining <= 0.0

func reset_lightning_storm_cooldown() -> void:
	lightning_storm_cooldown_remaining = 0.0
	clear_virtual_lightning_storm()

func set_heal_cooldown(remaining: float, duration: float) -> void:
	heal_cooldown_remaining = maxf(0.0, remaining)
	heal_cooldown_duration = maxf(0.01, duration)

func get_heal_cooldown_remaining() -> float:
	return heal_cooldown_remaining

func get_heal_cooldown_duration() -> float:
	return heal_cooldown_duration

func get_heal_cooldown_ratio() -> float:
	return clampf(heal_cooldown_remaining / heal_cooldown_duration, 0.0, 1.0)

func is_heal_ready() -> bool:
	return heal_cooldown_remaining <= 0.0

func reset_heal_cooldown() -> void:
	heal_cooldown_remaining = 0.0
	clear_virtual_heal()

func set_attack_held(value: bool) -> void:
	attack_held = value

func is_attack_held() -> bool:
	return attack_held or Input.is_action_pressed("attack")

func set_auto_attack_enabled(value: bool) -> void:
	auto_attack_enabled = value

func toggle_auto_attack() -> void:
	auto_attack_enabled = not auto_attack_enabled

func is_auto_attack_enabled() -> bool:
	return auto_attack_enabled

func clear_virtual_inputs() -> void:
	clear_virtual_move()
	clear_virtual_attack()
	clear_virtual_dash()
	clear_virtual_scatter()
	clear_virtual_sword_rain()
	clear_virtual_lightning_storm()
	clear_virtual_heal()
	attack_held = false
