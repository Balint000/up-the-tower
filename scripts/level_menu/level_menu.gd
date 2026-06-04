extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the buttons that aren't wired in the scene file.
	$ScrollContainer/LevelsGrid/LevelCard_01/SelectBtn_01.pressed.connect(_on_level_1_btn_pressed)
	$ScrollContainer/LevelsGrid/LevelCard_02/TextureButton.pressed.connect(_on_level_2_btn_pressed)
	$ScrollContainer/LevelsGrid/LevelCard_03/TextureButton.pressed.connect(_on_level_3_btn_pressed)
	$ScrollContainer/LevelsGrid/LevelCard_04/TextureButton.pressed.connect(_on_level_4_btn_pressed)

	# Grey out locked levels so the player knows they aren't available yet.
	$ScrollContainer/LevelsGrid/LevelCard_02/TextureButton.disabled = not LevelManager.is_unlocked(1)
	$ScrollContainer/LevelsGrid/LevelCard_03/TextureButton.disabled = not LevelManager.is_unlocked(2)
	$ScrollContainer/LevelsGrid/LevelCard_04/TextureButton.disabled = not LevelManager.is_unlocked(3)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_level_1_btn_pressed() -> void:
	LevelManager.load_level(0)
	print("Pressed Lvl 1")

func _on_level_2_btn_pressed() -> void:
	LevelManager.load_level(1)
	print("Pressed Lvl 2")
	
func _on_level_3_btn_pressed() -> void:
	LevelManager.load_level(2)
	print("Pressed Lvl 3")
	
func _on_level_4_btn_pressed() -> void:
	LevelManager.load_level(3)
	print("Pressed Lvl 4")

func _on_btn_back_pressed() -> void:
	GameManager.go_to_mainmenu()

func _check_locked() -> void:
	pass
