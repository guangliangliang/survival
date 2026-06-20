extends Node2D

@export var damage: float = 10.0
@export var fire_rate: float = 10.0
@export var bullet_speed: float = 500.0
@export var bullet_scene: PackedScene
@export var bullet_pool_size: int = 50
@export var fire_range: float = 400.0

var fire_timer: Timer = Timer.new()
var can_fire: bool = true
var bullet_pool = []
var weapon_sprite = null
var current_angle = 0.0

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
	
	weapon_sprite = get_node_or_null("Sprite2D")

func fire():
	if not can_fire:
		return
	
	# 找最近的敌人
	var target = null
	var min_dist = INF
	
	for node in get_tree().get_nodes_in_group("enemy"):
		var dist = global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			target = node
	
	# 如果有敌人，检查射程
	if target:
		if min_dist > fire_range:
			return  # 超出射程，不开火
	else:
		return  # 没有敌人，不开火
	
	can_fire = false
	fire_timer.start()
	
	_play_fire_animation()
	
	var bullet = _get_bullet_from_pool()
	if bullet:
		bullet.global_position = global_position
		var direction = (target.global_position - global_position).normalized()
		
		bullet.direction = direction
		bullet.speed = bullet_speed
		bullet.damage = damage
		bullet.active = true
		bullet.visible = true

func _play_fire_animation():
	if weapon_sprite:
		pass

func _get_bullet_from_pool():
	for bullet in bullet_pool:
		if not bullet.active:
			return bullet
	return null

func _find_nearest_enemy():
	var nearest = null
	var min_distance = INF
	
	# 获取所有敌人组的节点
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		# 检查敌人是否有生命值组件并且还活着
		var health_comp = enemy.get_node_or_null("HealthComponent")
		if health_comp and health_comp.current_health > 0:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = enemy
	return nearest

func _on_fire_cooldown_finished():
	can_fire = true
