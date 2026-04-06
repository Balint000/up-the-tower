extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the buttons that aren't wired in the scene file.
	$VBoxContainer/level2_btn.pressed.connect(_on_level_2_btn_pressed)
	$VBoxContainer/level3_btn.pressed.connect(_on_level_3_btn_pressed)
 
	# Grey out locked levels so the player knows they aren't available yet.
	$VBoxContainer/level2_btn.disabled = not LevelManager.is_unlocked(1)
	$VBoxContainer/level3_btn.disabled = not LevelManager.is_unlocked(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_btn_pressed() -> void:
	GameManager.go_to_mainmenu()


func _on_level_1_btn_pressed() -> void:
	LevelManager.load_level(0)
	print("Pressed Lvl 1")

func _on_level_2_btn_pressed() -> void:
	LevelManager.load_level(1)
	print("Pressed Lvl 2")
	
func _on_level_3_btn_pressed() -> void:
	LevelManager.load_level(2)
	print("Pressed Lvl 3")
