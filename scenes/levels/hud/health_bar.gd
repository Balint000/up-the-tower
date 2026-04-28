extends Control

signal health_changed(current, max)
signal died

@onready var bar: ProgressBar = $MarginContainer/ProgressBar

var max_health: float = 100
var health: float = 100

# animáció sebesség (minél kisebb → gyorsabb)
var smooth_speed := 0.15

func _ready():
	_update_immediate()

# --- PUBLIC API --- #

func set_max_health(value: float):
	max_health = max(value, 1)
	health = clamp(health, 0, max_health)

	bar.max_value = max_health
	_update_immediate()

func set_health(value: float):
	var old_health = health
	health = clamp(value, 0, max_health)

	_animate_change(old_health, health)

	emit_signal("health_changed", health, max_health)

	if health <= 0:
		emit_signal("died")

func take_damage(amount: float):
	if amount <= 0:
		return
	set_health(health - amount)

func heal(amount: float):
	if amount <= 0:
		return
	set_health(health + amount)

# --- INTERNAL --- #

func _update_immediate():
	bar.value = health

func _animate_change(old_value: float, new_value: float):
	var tween = create_tween()
	tween.tween_property(bar, "value", new_value, smooth_speed)

	# kis "impact" effekt (finom scale animáció)
	bar.scale = Vector2(1.05, 1.05)
	var scale_tween = create_tween()
	scale_tween.tween_property(bar, "scale", Vector2.ONE, 0.1)

## hasznalat
# @onready var health_bar = $HUD/HealthBar

#func _ready():
#    health_bar.set_max_health(100)
#    health_bar.set_health(100)

#func take_hit():
#    health_bar.take_damage(20)

#func heal_player():
#    health_bar.heal(10)
