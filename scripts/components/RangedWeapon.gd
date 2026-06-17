extends Node2D

@export var damage: float = 10.0
@export var fire_rate: float = 10.0
@export var bullet_speed: float = 500.0
@export var bullet_scene
@export var bullet_pool_size: int = 50

var fire_timer: Timer = Timer.new()
var can_fire: bool = true
var bullet_pool = []
var target = null
var weapon_sprite = null

func _ready():
	add_child(fire_timer)
	fire_timer.wait_time = 1.0 / fire_rate
	fire_timer.timeout.connect(_on_fire_cooldown_finished)
	
	for i in range(bullet_pool_size):
		var bullet = bullet_scene.instantiate()
		bullet.visible = false
		bullet.active = false
		get_tree().root.add_child(bullet)
		bullet_pool.append(bullet)
	
	target = GameManager.player
	weapon_sprite = get_node_or_null("Sprite2D")

func fire():
	if not can_fire or not target:
		return
	
	can_fire = false
	fire_timer.start()
	
	_play_fire_animation()
	
	var bullet = _get_bullet_from_pool()
	if bullet:
		bullet.global_position = global_position
		var nearest_enemy = _find_nearest_enemy()
		var direction: Vector2
		if nearest_enemy:
			direction = (nearest_enemy.global_position - global_position).normalized()
		else:
			direction = Vector2.RIGHT
		
		bullet.direction = direction
		bullet.speed = bullet_speed
		bullet.damage = damage
		bullet.active = true
		bullet.visible = true

func _play_fire_animation():
	if weapon_sprite:
		pass
		# 这里将来可以播放射击动画

func _get_bullet_from_pool():
	for bullet in bullet_pool:
		if not bullet.active:
			return bullet
	return null

func _find_nearest_enemy():
	var nearest = null
	var min_distance = INF
	
	for child in get_tree().root.get_node("Game/GameWorld").get_children():
		if child.is_in_group("enemy") and child.has_method("is_alive") and child.is_alive:
			var distance = global_position.distance_to(child.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = child
	return nearest

func _on_fire_cooldown_finished():
	can_fire = true
