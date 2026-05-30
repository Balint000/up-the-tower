extends BasePlayer

@onready var _camera:    Camera2D = $Camera2D  if has_node("Camera2D")  else null
@onready var _inventory: Node     = $Inventory if has_node("Inventory") else null

func _get_animation_name() -> StringName:
	match _state:
		State.IDLE: return &"idle"
		State.RUN: return &"walk"
		State.JUMP: return &"idle"
		State.FALL: return &"idle"
		State.ATTACK: return &"attack"
		State.HURT: return &"hurt"
		State.DEAD: return &"death"
	return &"idle"

func _use_selected_item() -> void:
	if _inventory != null and _inventory.has_method("use_selected"):
		_inventory.use_selected(self)
		emit_signal("stats_changed", self)
