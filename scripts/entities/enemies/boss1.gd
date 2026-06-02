## boss1.gd
## ==========================================================================
## Two-phase boss enemy, integrated into the existing enemy architecture.
##
## Inheritance chain:  Boss → BaseEnemy → Entity → CharacterBody2D
##
## ── Phase 1 (HP > 50 %) ────────────────────────────────────────────────────
##   Slow, persistent chase followed by a melee strike.
##   Simple AI: locate the player, follow, hit.
##
## ── Phase 2 (HP ≤ 50 %) ────────────────────────────────────────────────────
##   Faster movement. Two special actions alternate:
##   • JUMP   – leaps above the player and deals damage on landing
##   • CHARGE – short wind-up → direction-locked dash → recovery
##              (based on [ChargerEnemy] logic)
##
## Required scene structure (the .tscn is created by the developer):
##   Boss (CharacterBody2D)
##   ├── AnimatedSprite2D
##   │     clips: idle, walk, attack, hurt, death
##   │     optional: jump, charge, windup
##   ├── CollisionShape2D
##   ├── RayCastRight  (BaseEnemy patrol raycast – not strictly needed for the boss)
##   └── RayCastLeft
##
## Compatible with [EnemySpawner]: the class inherits [BaseEnemy], so
## [code]scene.instantiate() as BaseEnemy[/code] works correctly.
## ==========================================================================
class_name Boss
extends BaseEnemy

# Phase tracking

## Current combat phase (1 or 2).
var _phase: int = 1

## Guards against the Phase 2 transition running more than once.
var _phase2_triggered: bool = false

# Phase 1 settings

@export_group("Phase 1")

## Chase speed in Phase 1 (px/s).
@export var p1_speed: float = 60.0

## Melee attack range in Phase 1 (px).
@export var p1_attack_range: float = 40.0

## Minimum time between melee strikes in Phase 1 (s).
@export var p1_attack_cooldown: float = 1.8

# Phase 2 base settings

@export_group("Phase 2")

## Chase speed in Phase 2 (px/s).
@export var p2_speed: float = 110.0

## Melee attack range in Phase 2 (px).
@export var p2_attack_range: float = 45.0

## Minimum time between melee strikes in Phase 2 (s).
@export var p2_attack_cooldown: float = 0.8

# Jump attack (Phase 2)

@export_group("Jump Attack (Phase 2)")

## Minimum time between consecutive jump attacks (s).
@export var jump_interval: float = 4.0

## Initial upward velocity for the jump (negative = upward).
@export var jump_up_velocity: float = -380.0

## Horizontal speed toward the player during the jump (px/s).
@export var jump_h_speed: float = 270.0

# Charge attack (Phase 2)

@export_group("Charge Attack (Phase 2)")

## Minimum time between consecutive charge attacks (s).
@export var charge_interval: float = 6.0

## Duration of the wind-up (telegraph) animation before the dash begins (s).
@export var charge_windup_time: float = 0.9

## Horizontal dash speed during the charge (px/s).
@export var charge_speed: float = 490.0

## Maximum duration of the charge dash (s).
@export var charge_duration: float = 0.5

## Damage multiplier applied during the charge (base damage × this value).
@export var charge_dmg_multiplier: float = 2.0

## Recovery pause duration after a successful (clean) charge (s).
@export var charge_recovery_time: float = 0.65

## Stun duration applied when the charge ends by hitting a wall (s).
@export var charge_wall_stun: float = 2

# Runtime state variables

## [code]true[/code] while the boss is airborne in the jump arc.
var _is_jumping: bool = false
## Locked horizontal direction for the jump: [code]1.0[/code] = right, [code]-1.0[/code] = left.
var _jump_dir: float = 1.0
## Whether the boss was on the floor in the previous frame (used for landing detection).
var _was_on_floor: bool = true

## [code]true[/code] during the wind-up phase that precedes the charge.
var _is_winding_up: bool = false
## Remaining wind-up time before the charge dash begins (s).
var _windup_timer: float = 0.0

## [code]true[/code] while the charge dash is actively running.
var _is_charging: bool = false
## Locked horizontal direction for the charge dash; cannot change after the dash starts.
var _charge_dir: float = 1.0
## Remaining time in the current charge dash (s).
var _charge_timer: float = 0.0
## [code]true[/code] if the player has already been hit during this charge,
## preventing multiple hits within a single dash.
var _charge_hit_player: bool = false

## [code]true[/code] during the post-charge recovery (or wall-stun) pause.
var _is_recovering: bool = false
## Remaining recovery or stun time (s).
var _recovery_timer: float = 0.0

## Cooldown until the next jump attack is allowed (s).
var _jump_cd: float = 3.0

## Cooldown until the next charge attack is allowed (s).
## The initial offset prevents the first jump and charge from triggering simultaneously.
var _charge_cd: float = 6.0

# Signals

## Emitted when the boss transitions to a new phase.
## [param new_phase] The phase number that was just entered (always [code]2[/code] currently).
signal phase_changed(new_phase: int)

## Emitted when the boss dies, before [method Node.queue_free] is called.
signal boss_died()

# Ready

## Applies Phase 1 stats and immediately enters AGGRO state (the boss never patrols).
func _ready() -> void:
	super._ready()

	# Apply Phase 1 statistics to the inherited BaseEnemy fields.
	attack_range = p1_attack_range
	attack_cooldown = p1_attack_cooldown
	chase_speed = p1_speed
	aggro_range = 230.0
	lose_aggro_range = 550.0

	# The boss starts chasing immediately — skip the PATROL state entirely.
	_set_state(State.AGGRO)

# Main physics loop

## Physics update: ticks all cooldowns, checks the phase transition, handles
## high-priority special states (recovery, charge, wind-up), then runs the
## normal state machine, and finally detects jump landings.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	# Decrement the melee attack cooldown.
	_attack_timer = max(0.0, _attack_timer - delta)

	# Apply gravity while the boss is airborne.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Check for a phase transition on every frame.
	_tick_phase_transition()

	# Advance Phase 2 special-action cooldowns.
	if _phase == 2:
		_jump_cd = max(0.0, _jump_cd - delta)
		_charge_cd = max(0.0, _charge_cd - delta)

	# ── Priority special states (highest priority first) ─────────────────────

	# 1. Recovery / wall-stun – the boss cannot move.
	if _is_recovering:
		_recovery_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0)
		if _recovery_timer <= 0.0:
			_is_recovering = false
			_set_state(State.AGGRO)
		move_and_slide()
		_update_animation()
		return

	# 2. Active charge dash – direction is locked for the duration.
	if _is_charging:
		_charge_timer -= delta
		velocity.x = _charge_dir * charge_speed

		# Wall collision during the charge → apply stun via _end_charge.
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if abs(col.get_normal().x) > 0.5:
				_end_charge(true)
				move_and_slide()
				_update_animation()
				return

		# Hit the player – only once per charge to avoid per-frame damage.
		if not _charge_hit_player and _player != null \
				and global_position.distance_to(_player.global_position) <= attack_range + 20.0:
			_charge_hit_player = true
			if _player.has_method("take_damage"):
				_player.take_damage(
					int(damage * charge_dmg_multiplier),
					Vector2(_charge_dir * 370.0, -210.0)
				)
			_end_charge(false)
			move_and_slide()
			_update_animation()
			return

		if _charge_timer <= 0.0:
			_end_charge(false)

		move_and_slide()
		_update_animation()
		return

	# 3. Wind-up (charge preparation) – boss decelerates while telegraphing.
	if _is_winding_up:
		_windup_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0)
		if _windup_timer <= 0.0:
			_is_winding_up = false
			_begin_charge()
		move_and_slide()
		_update_animation()
		return

	# ── Normal state machine ─────────────────────────────────────────────────

	match _state:
		State.PATROL:
			# The boss does not patrol; transition to AGGRO as soon as the player is found.
			if _player != null:
				_set_state(State.AGGRO)
			else:
				velocity.x = move_toward(velocity.x, 0.0, chase_speed)

		State.AGGRO:
			_do_boss_aggro()

		State.ATTACK:
			# Decelerate horizontally while the melee strike animation plays.
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)

		State.HURT:
			# Knockback velocity is set by take_damage; nothing extra to do here.
			pass

		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

	# ── Landing detection (end of jump attack) ───────────────────────────────
	if _is_jumping and is_on_floor() and not _was_on_floor:
		_on_jump_land()

	_was_on_floor = is_on_floor()
	_check_aggro()
	_update_animation()

# ── Phase transition ──────────────────────────────────────────────────────────

## Checks every frame whether the HP threshold for Phase 2 has been crossed.
## Does nothing if the transition already occurred or if max health is invalid.
func _tick_phase_transition() -> void:
	if _phase2_triggered or max_health <= 0:
		return
	if float(health) / float(max_health) <= 0.5:
		_enter_phase_2()


## Activates Phase 2: updates chase speed, attack range, and cooldown,
## applies a short stagger, then emits [signal phase_changed].
func _enter_phase_2() -> void:
	_phase2_triggered = true
	_phase = 2

	chase_speed = p2_speed
	attack_range = p2_attack_range
	attack_cooldown = p2_attack_cooldown

	# Brief stagger on phase transition to give the player a visual cue.
	_set_state(State.HURT)
	velocity = Vector2.ZERO

	print("[Boss] PHASE 2")
	phase_changed.emit(2)

# ── Boss AGGRO movement logic ─────────────────────────────────────────────────

## Chase behaviour. In Phase 2, also triggers jump and charge attacks
## when their respective cooldowns have elapsed.
func _do_boss_aggro() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Melee attack takes priority over all other actions.
	if dist <= attack_range and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		_do_attack()
		return

	# Phase 2 special actions.
	if _phase == 2:
		# Jump attack: the boss cannot jump again while already airborne.
		if _jump_cd <= 0.0 and not _is_jumping and is_on_floor() \
				and dist > attack_range + 15.0:
			_begin_jump()
			return

		# Charge: only when the player is far enough and the boss is not jumping.
		if _charge_cd <= 0.0 and not _is_jumping \
				and dist > attack_range + 55.0:
			_begin_windup()
			return

	# Default movement: walk straight toward the player.
	var move_dir = sign(_player.global_position.x - global_position.x)
	velocity.x = move_dir * chase_speed
	if _sprite:
		_sprite.flip_h = move_dir < 0.0

# ── Jump attack ───────────────────────────────────────────────────────────────

## Launches the boss jump attack toward the player's current position.
## Sets [member _is_jumping] and applies both horizontal and vertical velocity.
## Resets [member _jump_cd] to enforce the cooldown interval.
func _begin_jump() -> void:
	if _player == null:
		return

	_is_jumping = true
	_jump_dir = sign(_player.global_position.x - global_position.x)
	velocity.x = _jump_dir * jump_h_speed
	velocity.y = jump_up_velocity
	_jump_cd = jump_interval

	if _sprite:
		_sprite.flip_h = _jump_dir < 0.0


## Called when the boss lands after a jump attack.
## Deals [member Entity.damage] with a horizontal knockback if the player
## is within [member BaseEnemy.attack_range] + 35 px of the landing position.
func _on_jump_land() -> void:
	_is_jumping = false
	if _player != null \
			and global_position.distance_to(_player.global_position) <= attack_range + 35.0:
		if _player.has_method("take_damage"):
			_player.take_damage(damage, Vector2(_jump_dir * 200.0, -160.0))

# ── Charge attack ─────────────────────────────────────────────────────────────

## Starts the charge wind-up phase (telegraph).
## Enters ATTACK state, starts [member _windup_timer], and immediately resets
## [member _charge_cd] to prevent the action from looping before the dash finishes.
func _begin_windup() -> void:
	_set_state(State.ATTACK)
	_is_winding_up = true
	_windup_timer = charge_windup_time
	_charge_cd = charge_interval   # Reset cooldown immediately to prevent re-triggering.


## Locks in the charge direction and starts the active dash.
## Called automatically when [member _windup_timer] expires in [method _physics_process].
## Falls back to AGGRO if [member BaseEnemy._player] is null.
func _begin_charge() -> void:
	if _player == null:
		_set_state(State.AGGRO)
		return

	attack_range = 25
	_charge_dir = sign(_player.global_position.x - global_position.x)
	_is_charging = true
	_charge_timer = charge_duration
	_charge_hit_player = false

	if _sprite:
		_sprite.flip_h = _charge_dir < 0.0


## Ends the charge dash and transitions to recovery or wall-stun.
## [param wall_hit] Pass [code]true[/code] if the charge was stopped by a wall collision;
## [code]false[/code] for a clean (timed-out or player-hit) charge end.
func _end_charge(wall_hit: bool) -> void:
	_is_charging = false
	velocity.x = 0.0
	attack_range = p2_attack_range

	if wall_hit:
		# Wall collision → longer stun penalty.
		_set_state(State.HURT)
		_is_recovering = true
		_recovery_timer = charge_wall_stun
	else:
		# Clean charge end → short recovery pause before returning to AGGRO.
		_is_recovering = true
		_recovery_timer = charge_recovery_time
		_set_state(State.AGGRO)

# Animation

## Plays the appropriate animation clip for the current state and special flags.
## Special states ([member _is_charging], [member _is_winding_up],
## [member _is_jumping], [member _is_recovering]) take priority over the
## base state-machine animations. Falls back to [code]"walk"[/code] or
## [code]"idle"[/code] if optional clips are missing from the sprite sheet.
func _update_animation() -> void:
	if _sprite == null:
		return

	# Special states override normal state-machine animations.
	if _is_charging:
		var clip: StringName = &"charge" \
			if _sprite.sprite_frames.has_animation("charge") else &"walk"
		_sprite.play(clip)
		return

	if _is_winding_up:
		var clip: StringName = &"windup" \
			if _sprite.sprite_frames.has_animation("windup") else &"idle"
		_sprite.play(clip)
		return

	if _is_jumping:
		var clip: StringName = &"jump" \
			if _sprite.sprite_frames.has_animation("jump") else &"walk"
		_sprite.play(clip)
		return

	if _is_recovering:
		_sprite.play("hurt")
		return

	match _state:
		State.PATROL, State.AGGRO:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.ATTACK:
			_sprite.play("attack")
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")

# Death

## Overrides [method BaseEnemy._on_died]: plays a longer death sequence and
## notifies [LevelManager] to advance to the next level when finished.
## Emits [signal boss_died] before the delay, then calls
## [method LevelManager.on_level_complete] after 2 seconds.
func _on_died() -> void:
	boss_died.emit()
	print("[Boss] Defeated!")

	if GameManager != null:
		var stats: Dictionary = GameManager.runtime_data.get(
			GameManager.KEY_STATISTICS, {}
		)
		stats[GameManager.KEY_KILLS] = stats.get(GameManager.KEY_KILLS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats

	await get_tree().create_timer(2.0).timeout

	if not is_instance_valid(self):
		return

	# Level complete → LevelManager advances to the next level.
	if LevelManager != null:
		LevelManager.on_level_complete()
	else:
		queue_free()
