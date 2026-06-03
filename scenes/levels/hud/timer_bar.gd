extends Control

signal finished  # amikor FULL-on van

@onready var bar: ProgressBar = $MarginContainer/ProgressBar

# 1. LÉPÉS: Állapotok definiálása az időzítőhöz
enum TimerState { NORMAL, BLOCK_DOWN, BLOCK_UP }
var current_state = TimerState.NORMAL

var max_time: float = 5.0
var current_time: float = 0.0
var running: bool = false

# Időzítők az X és Y fázisok hátralévő idejének követésére
var block_down_remaining: float = 0.0
var block_up_remaining: float = 0.0

# --- START CHARGE ---
func start_cooldown(time: float):
	max_time = max(time, 0.1)
	current_time = 0.0
	running = true
	current_state = TimerState.NORMAL # Alapállapotból indul

	bar.max_value = max_time
	bar.value = 0.0

func reset():
	running = false
	current_time = 0
	bar.value = 0
	current_state = TimerState.NORMAL
	
# 2. LÉPÉS: A block aktiválása az X (lefele) és Y (felfele) értékekkel
func trigger_block_ability(x_amount: float, y_amount: float):
	if not running:
		return
		
	current_state = TimerState.BLOCK_DOWN
	block_down_remaining = x_amount
	block_up_remaining = y_amount

func _process(delta):
	if not running:
		return

	# 3. LÉPÉS: Az állapotgép futtatása fázisonként
	match current_state:
		TimerState.NORMAL:
			# ALAPÉRTELMEZETT: Felfelé számol
			current_time += delta
			current_time = min(current_time, max_time)
			
		TimerState.BLOCK_DOWN:
			# FÁZIS 1: Lefelé számol X mennyiséget
			var decrease = min(delta, block_down_remaining)
			current_time -= decrease
			current_time = max(current_time, 0.0) # Ne menjen 0 alá
			block_down_remaining -= decrease
			
			# Ha az X idő elfogyott, váltunk az Y fázisra
			if block_down_remaining <= 0:
				current_state = TimerState.BLOCK_UP
				
		TimerState.BLOCK_UP:
			# FÁZIS 2: Felfelé számol Y mennyiséget
			var increase = min(delta, block_up_remaining)
			current_time += increase
			current_time = min(current_time, max_time) # Ne lépje túl a maxot
			block_up_remaining -= increase
			
			# Ha az Y idő is elfogyott, visszatér a normál működéshez
			if block_up_remaining <= 0:
				current_state = TimerState.NORMAL

	# 4. LÉPÉS: Vizuális megjelenítés (Lerp és Modulate)
	bar.value = lerp(bar.value, current_time, 0.2)
	
	if current_time >= max_time:
		bar.modulate = Color(1.2, 1.2, 1.2)
		# Csak akkor fejezzük be, ha a normál működésben érte el a maximumot
		if current_state == TimerState.NORMAL:
			bar.value = max_time # Kényszerítsük a pontos értékre a lerp miatt
			running = false
			emit_signal("finished")
	else:
		bar.modulate = Color(1, 1, 1)
