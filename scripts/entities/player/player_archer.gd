class_name PlayerArcher
extends BasePlayer

@onready var _camera:    Camera2D = $Camera2D  if has_node("Camera2D")  else null
@onready var _inventory: Node     = $Inventory if has_node("Inventory") else null

func _get_animation_name() -> StringName:
	match _state:
		State.IDLE:   return &"idle"
		State.RUN:    return &"walk"
		State.JUMP:   return &"idle"
		State.FALL:   return &"idle"
		State.ATTACK: return &"attack"
		State.HURT:   return &"hurt"
		State.DEAD:   return &"death"
	return &"idle"

func _use_selected_item() -> void:
	if _inventory != null and _inventory.has_method("use_selected"):
		_inventory.use_selected(self)
		emit_signal("stats_changed", self)

## @brief Felülírja a melee támadást: nyilat lő ki a néző irányába.
## Ha projectile_scene nincs beállítva, push_warning-ot dob.
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
