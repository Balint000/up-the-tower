## Manages a single active ability for the player character.
##
## Supported ability types: [code]"dash"[/code], [code]"double_jump"[/code],
## [code]"block"[/code], [code]"fireball"[/code].
## The owning [BasePlayer] holds a reference to this component as [member BasePlayer._ability].
## [method tick] must be called every physics frame to advance the cooldown timer.
## [method activate] executes the ability and starts the cooldown.
##
## Ability details:[br]
## - [b]dash[/b]: applies a horizontal impulse in the facing direction.[br]
## - [b]double_jump[/b]: grants an extra jump while airborne.[br]
## - [b]block[/b]: sets [member BasePlayer.is_blocking] for 6 seconds, reducing incoming damage by [member ability_power].[br]
## - [b]fireball[/b]: delegates to [method BasePlayer.spawn_projectile].
class_name AbilityComponent
extends Node2D

## Reference to the owning [BasePlayer]. Set by [method setup].
var _player: BasePlayer = null

## Identifier of the ability granted by the character's [CharacterResource].
var ability_type: String = "none"
## Time in seconds before the ability can be used again after activation.
var ability_cooldown: float = 0.0
## Numeric power value whose meaning depends on the ability type
## (impulse speed for dash, jump force for double jump, block ratio for block,
## damage for fireball).
var ability_power: float = 0.0
## Remaining cooldown time (seconds). Counts down in [method tick].
var _cd_timer: float = 0.0

## Emitted when an ability is successfully activated.
## [param type] The [member ability_type] string of the activated ability.
signal ability_used(type: String, cd)
## Emitted when the cooldown timer reaches zero and the ability becomes usable again.
signal ability_ready()


## Configures this component from a [CharacterResource].
## Called by [method BasePlayer.set_character_resource].
## [param player] The owning [BasePlayer] node.
## [param res] The character's [CharacterResource] containing ability configuration.
func setup(player: BasePlayer, res: CharacterResource) -> void:
	_player = player
	ability_type = res.ability_type
	ability_cooldown = res.ability_cooldown
	ability_power = res.ability_power
	add_to_group("ability")


## Advances the cooldown timer by [param delta] seconds.
## Emits [signal ability_ready] when the timer crosses zero.
## Must be called from [method BasePlayer._physics_process].
func tick(delta: float) -> void:
	var was_ready := _cd_timer <= 0.0
	_cd_timer = max(0.0, _cd_timer - delta)
	if not was_ready and _cd_timer <= 0.0:
		emit_signal("ability_ready")

## Returns [code]true[/code] if the ability cooldown has fully elapsed.
func is_ready() -> bool:
	return _cd_timer <= 0.0


## Activates the ability if it is ready and the ability type is known.
## Starts the cooldown and emits [signal ability_used] on success.
func activate() -> void:
	if ability_type == "none" or not is_ready() or _player == null:
		return
	match ability_type:
		"dash": _do_dash()
		"double_jump": _do_double_jump()
		"block": _do_block()
		"fireball": _do_fireball()
	_cd_timer = ability_cooldown
	emit_signal("ability_used", ability_type, ability_cooldown)


## Applies a horizontal velocity impulse in the player's facing direction.
## Sets [member BasePlayer._is_dashing] and [member BasePlayer._dash_timer] so
## that [method BasePlayer._handle_movement] bypasses normal input during the dash.
func _do_dash() -> void:
	var dir := 1.0 if _player._facing_right else -1.0
	_player.velocity.x = dir * ability_power
	_player._is_dashing = true
	_player._dash_timer = _player.dash_duration


## Grants an extra jump by setting a negative vertical velocity.
## Only activates when the player is airborne (ground jumps use normal input).
func _do_double_jump() -> void:
	if not _player.is_on_floor():
		_player.velocity.y = -absf(ability_power)


## Activates a damage-reduction shield for 6 seconds.
## [member BasePlayer.is_blocking] is checked by [method BasePlayer.take_damage]
## to scale incoming damage by [code](1 - ability_power)[/code].
## [member ability_power] should be in the range [code]0.0–1.0[/code]; 0.5 = 50 % reduction.
func _do_block() -> void:
	_player.is_blocking = true
	await _player.get_tree().create_timer(6).timeout
	# Guard against the player dying while the block was active.
	if is_instance_valid(_player):
		_player.is_blocking = false


## Fires a projectile by calling [method BasePlayer.spawn_projectile].
## The [member BasePlayer.projectile_scene] export must be set in the editor.
func _do_fireball() -> void:
	_player.spawn_projectile(ability_power)
