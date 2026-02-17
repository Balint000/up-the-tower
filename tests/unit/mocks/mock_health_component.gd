extends Node
# Mock health component for testing

signal health_changed(old_health, new_health)
signal died()

@export var max_health: int = 100
var current_health: int = 100

func _ready():
	current_health = max_health

func take_damage(amount: int) -> void:
	var old_health = current_health
	current_health = max(0, current_health - amount)
	
	health_changed.emit(old_health, current_health)
	
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	health_changed.emit(old_health, current_health)

func is_dead() -> bool:
	return current_health <= 0
