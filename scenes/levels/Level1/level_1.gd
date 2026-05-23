extends Node2D

@onready var health_bar = $Hud/CanvasLayer/VBoxContainer/HealthBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_bar.set_max_health(GameManager.player_data[GameManager.KEY_HP])
	health_bar.set_health(GameManager.player_data[GameManager.KEY_HP])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
