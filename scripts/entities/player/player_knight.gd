extends BasePlayer

@onready var _camera: Camera2D = $Camera2D if has_node("Camera2D")  else null
@onready var _inventory: Node = $Inventory if has_node("Inventory") else null

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

func _use_selected_item(item_id: String) -> void:
	super._use_selected_item(item_id)
