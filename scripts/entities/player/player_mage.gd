extends BasePlayer

@onready var _camera:    Camera2D = $Camera2D  if has_node("Camera2D")  else null
@onready var _inventory: Node     = $Inventory if has_node("Inventory") else null

## @export big_fireball_scene
## @brief A nagy tűzgolyó PackedScene-je. Editorban kötelező beállítani!
@export var big_fireball_scene: PackedScene = null

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


## @brief Normál támadás: mini tűzgolyó kilövése a néző irányába.
func _do_melee_attack() -> void:
	if not is_alive or _attack_cd_timer > 0.0:
		return

	if projectile_scene == null:
		push_warning("PlayerMage: projectile_scene (mini fireball) nincs beállítva!")
		return

	_state = State.ATTACK
	_attack_cd_timer = attack_cooldown

	spawn_projectile(float(damage))

	await get_tree().create_timer(0.35).timeout
	if _state == State.ATTACK:
		_state = State.IDLE


## @brief Képesség: nagy tűzgolyó kilövése emelt sebzéssel.
## A big_fireball_scene-t az editorban kell bekötni.
## ability_power szorzóként hat a damage-re.
func _do_ability() -> void:
	if _ability == null or not _ability.is_ready():
		return

	if big_fireball_scene == null:
		push_warning("PlayerMage: big_fireball_scene nincs beállítva!")
		return

	_state = State.ATTACK

	var big_power := float(damage) * (_ability.ability_power if _ability.ability_power > 0.0 else 2.0)
	var proj := big_fireball_scene.instantiate()
	if proj.has_method("setup"):
		proj.setup(
			global_position,
			1.0 if _facing_right else -1.0,
			int(big_power),
			"enemies"
		)
	get_tree().get_current_scene().add_child(proj)

	_ability._cd_timer = _ability.ability_cooldown
	_ability.emit_signal("ability_used", "big_fireball")

	await get_tree().create_timer(0.5).timeout
	if _state == State.ATTACK:
		_state = State.IDLE
