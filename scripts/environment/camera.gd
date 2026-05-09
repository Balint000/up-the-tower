extends Camera2D


## Függőleges eltolás (kicsit feljebb lát a karakter fölé)
@export var y_offset: float = -10.0

func _ready() -> void:
	# A kamera ne törlődjön, ha a player node megváltozik
	set_process(true)

func _physics_process(_delta: float) -> void:
	var target: BasePlayer = LevelManager.current_player
	if target == null or not is_instance_valid(target):
		return
	# Csak pozíciót frissítünk – a simítást a Camera2D Position Smoothing végzi
	global_position = target.global_position + Vector2(0.0, y_offset)
