extends Node2D

@onready var health_bar = $Hud/CanvasLayer/VBoxContainer/HealthBar
@onready var tutorial_sign_2: Area2D = %TutorialSign2
@onready var tutorial_sign_1: Area2D = %TutorialSign1
@onready var tutorial_sign_3: Area2D = $Signs/TutorialSign3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tutorial_sign_2._set_message("W or space to jump.")
	tutorial_sign_1._set_message("A and D or arrow keys to move.")
	tutorial_sign_3._set_message("Z for attack; shift for ability")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
