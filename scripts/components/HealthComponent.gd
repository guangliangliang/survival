extends Node

signal health_changed(current_health: float, max_health: float)
signal died

@export var max_health: float = 100.0
@export var invincible: bool = false
var current_health: float = 0.0

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if invincible or current_health <= 0:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func increase_max_health(amount: float, heal_amount: float = 0.0) -> void:
	max_health += amount
	current_health = min(current_health + heal_amount, max_health)
	health_changed.emit(current_health, max_health)

func reset(new_max_health: float = -1.0) -> void:
	if new_max_health > 0.0:
		max_health = new_max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)

func die() -> void:
	died.emit()
