extends Control

signal finished

@onready var bar: ProgressBar = $MarginContainer/ProgressBar
@onready var timer: Timer = $MarginContainer/Timer

enum State {
	IDLE,
	CHARGING
}

var state := State.IDLE

var max_time := 1.0
var current := 0.0
var step := 0.05


func _ready():
	timer.wait_time = step
	timer.one_shot = false
	timer.autostart = false
	timer.timeout.connect(_tick)

func start_cooldown(time: float):
	max_time = max(time, 0.1)

	current = 0.0
	state = State.CHARGING

	bar.max_value = max_time
	bar.value = current

	timer.start()

	await finished


func trigger_knight_block(x_time: float, y_time: float):
	
	bar.fill_mode = 1 
	await start_cooldown(x_time)
	
	bar.value = 0.0
	bar.fill_mode = 0 
	await start_cooldown(y_time)

func _tick():

	match state:
		State.CHARGING:
			current += step

	# clamp
	current = clamp(current, 0.0, max_time)

	# UI UPDATE
	bar.value = current

	# FINISH
	if current >= max_time:
		state = State.IDLE
		timer.stop()
		emit_signal("finished")
