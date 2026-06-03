class_name PlayerArcher
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

## Overrides melee attack: shoot an arrow where player sees.
## If projectile_scene not found -> push_warning
func _do_melee_attack() -> void:
	if not is_alive or _attack_cd_timer > 0.0:
		return

	if projectile_scene == null:
		push_warning("PlayerArcher: projectile_scene nincs beállítva! Kösd be az editorban.")
		return

	_state = State.ATTACK
	_attack_cd_timer = attack_cooldown

	spawn_projectile(float(damage))

	await get_tree().create_timer(0.4).timeout
	if _state == State.ATTACK:
		_state = State.IDLE
