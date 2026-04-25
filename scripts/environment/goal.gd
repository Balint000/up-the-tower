## goal.gd
## Attach to a Goal node (Area2D) placed at the top of every level.
## When the player walks into it, GameManager advances to the next level.
##
## Scene setup:
##   Goal (Area2D)  ← this script
##   └── CollisionShape2D

extends Area2D

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		LevelManager.on_level_complete()
