extends Node

signal health_changed(current_health: float, max_health: float)
signal died

@export var max_health: float = 100.0
var current_health: float = 0.0

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func die() -> void:
	died.emit()
