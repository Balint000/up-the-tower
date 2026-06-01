## Gravity-free floating enemy that moves in a sinusoidal (wave) pattern
## during patrol and flies directly toward the player when in AGGRO.
## Damages the player on contact (touch-based melee, no projectile).
extends BaseEnemy

## Horizontal travel speed while patrolling and chasing (pixels per second).
@export var float_speed: float = 55.0
## Vertical oscillation amplitude during patrol (pixels).
@export var vertical_amplitude: float = 28.0
## Vertical oscillation frequency during patrol (cycles per second).
@export var vertical_frequency: float = 2.2

## Accumulated time used to drive the sinusoidal vertical movement (seconds).
var _time: float = 0.0

## Sets [member Entity.gravity] to 0 (no falling), configures a short touch
## attack range, and reduces the aggro range to suit the enemy's behaviour.
func _ready() -> void:
	super._ready()
	gravity = 0.0     # This enemy floats; gravity is disabled entirely.
	attack_range = 18.0    # Touch-based: very small contact range.
	attack_cooldown = 0.8
	aggro_range = 130.0

## Physics update: advances [member _time] for the sine wave, runs the
## flying-specific state machine branches, then calls [method move_and_slide]
## and the inherited aggro check and animation update.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)
	_time += delta

	match _state:
		State.PATROL: _do_flying_patrol()
		State.AGGRO: _do_flying_chase()
		State.ATTACK: _do_contact_attack()
		State.HURT: pass
		State.DEAD: velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()

## Patrol movement: horizontal back-and-forth using the inherited raycasts for
## direction reversal, with a sinusoidal vertical component driven by [member _time].
func _do_flying_patrol() -> void:
	if _dir > 0.0 and _ray_right and _ray_right.is_colliding():
		_dir = -1.0
	elif _dir < 0.0 and _ray_left and _ray_left.is_colliding():
		_dir = 1.0

	velocity.x = _dir * float_speed
	# Vertical oscillation: sin wave scaled by amplitude.
	velocity.y = sin(_time * vertical_frequency) * vertical_amplitude
	if _sprite:
		_sprite.flip_h = _dir < 0.0

## Chase movement: flies in a straight line directly toward the player.
## Returns to PATROL when the player leaves [member BaseEnemy.lose_aggro_range].
## Transitions to ATTACK when within [member BaseEnemy.attack_range].
func _do_flying_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	if dist <= attack_range:
		_set_state(State.ATTACK)
		return

	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	if _sprite:
		_sprite.flip_h = dir.x < 0.0

## Contact attack: called while in the ATTACK state.
## Deals [member Entity.damage] to the player whenever the cooldown has elapsed
## and the player is alive and within [member BaseEnemy.attack_range].
## Returns to AGGRO if the player moves out of contact range.
func _do_contact_attack() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > attack_range + 5.0:
		_set_state(State.AGGRO)
		return

	if _attack_timer <= 0.0 and _player.is_alive:
		_player.take_damage(damage, Vector2.ZERO)
		_attack_timer = attack_cooldown

## Overrides [method BaseEnemy._update_animation] to use the [code]"walk"[/code]
## clip as the flying animation in all active states (the sprite sheet uses
## walk frames for the flap cycle).
func _update_animation() -> void:
	if _sprite == null:
		return
	match _state:
		State.PATROL, State.AGGRO, State.ATTACK:
			_sprite.play("walk")   # Reuses walk frames as the flapping cycle.
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")
