class_name AbilityComponent
extends Node2D

## Az ownernek (BasePlayer) szüksége van rá, hogy velocity-t és
## facing-et olvashasson/írhasson.
var _player: BasePlayer = null

var ability_type: String = "none"
var ability_cooldown: float = 0.0
var ability_power: float = 0.0
var _cd_timer: float = 0.0

signal ability_used(type: String)
signal ability_ready()

func setup(player: BasePlayer, res: CharacterResource) -> void:
	_player = player
	ability_type = res.ability_type
	ability_cooldown = res.ability_cooldown
	ability_power = res.ability_power

func tick(delta: float) -> void:
	var was_ready := _cd_timer <= 0.0
	_cd_timer = max(0.0, _cd_timer - delta)
	if not was_ready and _cd_timer <= 0.0:
		emit_signal("ability_ready")

func is_ready() -> bool:
	return _cd_timer <= 0.0

func activate() -> void:
	if ability_type == "none" or not is_ready():
		return
	match ability_type:
		"dash":         _do_dash()
		"double_jump":  _do_double_jump()
		"block":        _do_block()
		"fireball":     _do_fireball()
	_cd_timer = ability_cooldown
	emit_signal("ability_used", ability_type)

func _do_dash() -> void:
	var dir := 1.0 if _player._facing_right else -1.0
	_player.velocity.x = dir * ability_power

func _do_double_jump() -> void:
	if not _player.is_on_floor():
		_player.velocity.y = -abs(ability_power)

func _do_block() -> void:
	# Pl. flag set _player-en, amit take_damage() olvas
	_player.set_meta("is_blocking", true)
	await _player.get_tree().create_timer(0.6).timeout
	_player.set_meta("is_blocking", false)

func _do_fireball() -> void:
	# Fireball scene-t a player scene-ből veszi, nem itt hardcode-olva
	_player.spawn_projectile(ability_power)
