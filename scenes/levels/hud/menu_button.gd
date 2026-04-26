extends Control

signal menu_opened
signal menu_closed

@onready var button = $Button
@onready var panel = $Overlay/Panel
@onready var resume_btn = $Overlay/Panel/VBoxContainer/ResumeButton
@onready var quit_btn = $Overlay/Panel/VBoxContainer/QuitButton
@onready var overlay = $Overlay

var is_open := false

func _ready():
	button.pressed.connect(_on_button_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	overlay.visible = false

func _on_button_pressed():
	_toggle_menu()
	GameManager.set_state(GameManager.GameState.PAUSED)
	
func _on_resume_pressed():
	_toggle_menu()
	GameManager.set_state(GameManager.GameState.IN_GAME)

func _on_quit_pressed():
	GameManager.go_to_levelmenu()

func _toggle_menu():
	is_open = !is_open
	overlay.visible = is_open
	get_tree().paused = is_open

	if is_open:
		emit_signal("menu_opened")
	else:
		emit_signal("menu_closed")
