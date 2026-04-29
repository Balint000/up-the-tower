extends BasePlayer
## PlayerKnight – játszható lovag karakter.

@onready var _camera: Camera2D = $Camera2D if has_node("Camera2D") else null
@onready var _inventory: Node = $Inventory if has_node("Inventory") else null
## Ha az inventory scriptednek van class_name-je (pl. class_name Inventory),
## ezt írd át így: `@onready var _inventory: Inventory = $Inventory`

@export var hurt_flash_count: int   = 4
@export var hurt_flash_speed: float = 0.07

signal player_stats_changed()
signal player_died()

func _ready() -> void:
	super._ready()

	if GameManager == null:
		push_error("PlayerKnight: GameManager autoload is not availble!")
		return

	var selected_char_id: String = GameManager.runtime_data.get(GameManager.KEY_SELECTED_CHARACTER, "knight")
	var char_res: CharacterResource = DataDb.get_character(selected_char_id)
	if char_res == null:
		push_error("PlayerKnight: Cant find CharacterResource: " + selected_char_id)
		return

	set_character_resource(char_res)
	emit_signal("player_stats_changed")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return
	super._unhandled_input(event)


func _get_animation_name() -> StringName:
	match _state:
		State.IDLE:             return &"idle"
		State.RUN:              return &"walk"
		State.JUMP:             return &"idle"
		State.FALL:             return &"idle"
		State.ATTACK:           return &"attack"
		State.HURT:             return &"hurt"
		State.DEAD:             return &"death"
	return &"idle"


func _use_selected_item() -> void:
	if _inventory != null and _inventory.has_method("use_selected"):
		_inventory.use_selected(self)
		emit_signal("player_stats_changed")

func _do_ability() -> void:
	super._do_ability()

func _request_interaction() -> void:
	## Később ide jön az ajtó/trigger logika.
	pass


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, knockback)
	## super() már hívja _on_took_damage() / _on_died()-et, amiket itt override-olunk.


func _on_took_damage(amount: int) -> void:
	print("[Knight] Sebzés: -%d | HP: %d / %d" % [amount, health, max_health])
	_flash_sprite()
	emit_signal("player_stats_changed")


func _flash_sprite() -> void:
	if _sprite == null:
		return

	for i in hurt_flash_count:
		_sprite.visible = false
		await get_tree().create_timer(hurt_flash_speed).timeout
		_sprite.visible = true
		await get_tree().create_timer(hurt_flash_speed).timeout


func _on_died() -> void:
	print("[Knight] Died")
	emit_signal("player_died")

	if _hitbox != null:
		_hitbox.disabled = true

	if GameManager != null:
		var stats = GameManager.runtime_data.get(GameManager.KEY_STATISTICS, {}) # was :=
		stats[GameManager.KEY_DEATHS] = stats.get(GameManager.KEY_DEATHS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats
		GameManager.save_game()

	await get_tree().create_timer(0.7).timeout

	if LevelManager != null and LevelManager.has_method("on_player_death"):
		LevelManager.on_player_death()
