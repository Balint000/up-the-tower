extends Control

signal finished  # amikor FULL-on van

@onready var bar: ProgressBar = $MarginContainer/ProgressBar

var max_time: float = 5.0
var current_time: float = 0.0
var running: bool = false

# --- START CHARGE (ugyanaz mint cooldown, csak töltés) ---
func start_cooldown(time: float):
	max_time = max(time, 0.1)
	current_time = 0.0
	running = true

	bar.max_value = max_time
	bar.value = 0.0

func reset():
	running = false
	current_time = 0
	bar.value = 0

func _process(delta):
	if not running:
		return

	# FELFELÉ SZÁMOL
	current_time += delta
	current_time = min(current_time, max_time)
	
	bar.value = lerp(bar.value, current_time, 0.2)
	
	if current_time >= max_time:
		bar.modulate = Color(1.2, 1.2, 1.2)
	else:
		bar.modulate = Color(1, 1, 1)

	bar.value = current_time

	if current_time >= max_time:
		running = false
		emit_signal("finished")

## hasznalat:
#@onready var timer_bar = $HUD/TimerBar

#func use_ability():
#	if timer_bar.running:
#		return

#	timer_bar.start_cooldown(5.0)
