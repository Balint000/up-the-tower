extends Area2D
class_name Goal
## Pályavégi trigger. Ha a player belelép, jelez a LevelManagernek.

@export var one_shot: bool = true

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if one_shot and _triggered:
		return

	# Csak playerre reagálunk
	if not (body is Entity):
		return
	if body.faction != "player":
		return

	_triggered = true

	# Pálya teljesítve -> LevelManager kezeli a továbblépést / játék végét
	LevelManager.on_level_complete()
