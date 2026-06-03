## Melee enemy that telegraphs an attack with a visible wind-up, then
## charges horizontally at high speed.
##
## The charge sequence: ATTACK state → [member windup_time] second pause
## (telegraph) → dash at [member charge_speed] for [member charge_duration]
## seconds → optional stun if a wall is hit.
## During the charge the enemy deals double damage on contact with the player.
extends BaseEnemy

## Horizontal dash speed during a charge (pixels per second).
@export var charge_speed: float = 450.0
## Duration of the horizontal charge dash (seconds).
@export var charge_duration: float = 0.45
## Wind-up (telegraph) time before the charge starts (seconds).
## Gives the player a visible warning that a charge is incoming.
@export var windup_time: float = 0.7
## Stun duration applied when the charge ends by hitting a wall (seconds).
@export var stun_duration: float = 1.2

## True while the enemy is actively dashing.
var _is_charging: bool = false
## True while the enemy is stunned after a wall collision.
var _is_stunned: bool = false
## Direction of the current charge: [code]1.0[/code] = right, [code]-1.0[/code] = left.
var _charge_dir: float = 1.0
## Remaining time for the active charge (seconds).
var _charge_timer: float = 0.0
## [code]true[/code] if the player has already been hit during this charge,
## preventing multiple hits within a single dash.
var _charge_hit_player: bool = false
## Remaining wind-up time before the charge begins (seconds).
var _windup_timer: float = 0.0
## Remaining stun time after a wall collision (seconds).
var _stun_timer: float = 0.0

## Configures charger-appropriate ranges and overrides the attack cooldown
## to account for the full charge sequence duration.
func _ready() -> void:
	super._ready()
	attack_range = 40.0
	aggro_range = 170.0
	attack_cooldown = charge_duration + windup_time + stun_duration + 0.3

## Physics update: handles stun decay, active charge movement, wall-collision
## stun, and the wind-up countdown before delegating to the parent state machine.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	# Stun recovery
	if _is_stunned:
		_stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 300.0)
		if _stun_timer <= 0.0:
			_is_stunned = false
			_set_state(State.AGGRO)
		move_and_slide()
		return

	# Active charge
	if _is_charging:
		_charge_timer -= delta
		velocity.x = _charge_dir * charge_speed

		# Wall collision during charge → apply stun.
		if get_slide_collision_count() > 0:
			for i in get_slide_collision_count():
				var col := get_slide_collision(i)
				if abs(col.get_normal().x) > 0.5:
					_end_charge(true)
					break
					
		if not _charge_hit_player and _player != null \
				and global_position.distance_to(_player.global_position) <= attack_range + 20.0:
			_charge_hit_player = true
			if _player.has_method("take_damage"):
				_player.take_damage(
					int(damage),
					Vector2(_charge_dir * 370.0, -210.0)
				)
			_end_charge(false)
			move_and_slide()
			_update_animation()
			return

		if _charge_timer <= 0.0:
			_end_charge(false)

		# Deal double damage while physically overlapping the player.
		if _player and global_position.distance_to(_player.global_position) <= attack_range:
			_player.take_damage(damage * 2, Vector2(_charge_dir * 350.0, -180.0))

		move_and_slide()
		return

	match _state:
		State.PATROL:   _do_patrol()
		State.AGGRO:    _do_chase()
		State.ATTACK:
			# Count down wind-up; begin charge once it expires.
			if _windup_timer > 0.0:
				_windup_timer -= delta
				velocity.x = move_toward(velocity.x, 0.0, 350.0)
			elif not _is_charging:
				_begin_charge()
		State.HURT:     pass
		State.DEAD:     velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()

## Overrides the base melee attack to start the wind-up countdown instead
## of applying immediate damage. The charge itself starts in [method _physics_process].
func _do_attack() -> void:
	_windup_timer = windup_time

## Locks in the charge direction toward the player and begins the dash.
## Falls back to AGGRO if [member _player] is null.
func _begin_charge() -> void:
	if _player == null:
		_set_state(State.AGGRO)
		return
	_charge_dir   = sign(_player.global_position.x - global_position.x)
	_is_charging  = true
	_charge_timer = charge_duration
	_charge_hit_player = false

## Ends the charge, applying a stun if [param wall_hit] is true.
## On a clean charge (no wall), simply resets the attack cooldown.
## [param wall_hit] Whether the charge ended by hitting a wall.
func _end_charge(wall_hit: bool) -> void:
	_is_charging = false
	velocity.x   = 0.0
	if wall_hit:
		_is_stunned  = true
		_stun_timer  = stun_duration
		_set_state(State.HURT)
	else:
		_attack_timer = attack_cooldown
		_set_state(State.AGGRO)

## Overrides [method BaseEnemy._update_animation] to use the [code]"idle"[/code]
## clip during wind-up (a dedicated "windup" clip can replace it if available).
func _update_animation() -> void:
	if _sprite == null: return
	match _state:
		State.PATROL, State.AGGRO:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.ATTACK:
			# Wind-up telegraph animation — substitute "windup" clip if available.
			_sprite.play("idle")
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")
