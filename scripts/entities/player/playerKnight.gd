## playerKnight.gd
## Replaces the stub movement script on MainCharacter.tscn.
## Health lives here as a plain variable — a proper HealthComponent node
## will be wired up in the full phase once it's added to the scene.
##
## Input actions used (must exist in Project Settings → Input Map):
##   move_left   ← Left arrow / A
##   move_right  → Right arrow / D
##   jump        ↑ Up arrow / W / Space
##   attack      Z  (add this manually in the Input Map)

extends CharacterBody2D

# ---------------------------------------------------------------------------
# Tunables
# ---------------------------------------------------------------------------

const BASE_SPEED: float        = 120.0
const BASE_JUMP_VELOCITY: float = -300.0
const BASE_HEALTH: int          = 100
const BASE_DAMAGE: int          = 20

## Seconds after a hit where the player can't take damage again.
const INVINCIBILITY_DURATION: float = 0.5

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }
var _state: State = State.IDLE

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

var _speed: float
var _jump_vel: float
var _damage: int

var health: int
var max_health: int
var _inv_timer: float = 0.0
var _was_on_floor: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("player")
	_apply_character_stats()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_tick_invincibility(delta)

	match _state:
		State.IDLE, State.RUN:
			_move()
			_check_jump()
			_check_attack()
		State.JUMP, State.FALL:
			_move()
			_check_jump()
		State.ATTACK:
			# Lock horizontal movement during swing.
			velocity.x = move_toward(velocity.x, 0.0, _speed)
		State.HURT:
			# Knockback decays naturally; state exits after a short timer.
			velocity.x = move_toward(velocity.x, 0.0, _speed * 3.0 * delta)
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_update_state_from_physics()
	_update_animation()
	_was_on_floor = is_on_floor()

# ---------------------------------------------------------------------------
# Character stats (read from GameManager.player_data)
# ---------------------------------------------------------------------------

func _apply_character_stats() -> void:
	var pd   := GameManager.player_data
	_speed   = BASE_SPEED * pd.get(GameManager.KEY_SPEED, 1.0)
	_jump_vel = BASE_JUMP_VELOCITY
	_damage  = roundi(BASE_DAMAGE * pd.get(GameManager.KEY_DMG, 1.0))
	max_health = roundi(BASE_HEALTH * pd.get(GameManager.KEY_HP, 1.0))
	health   = max_health

# ---------------------------------------------------------------------------
# Physics helpers
# ---------------------------------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _tick_invincibility(delta: float) -> void:
	if _inv_timer > 0.0:
		_inv_timer -= delta

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _move() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_sprite.flip_h = dir < 0.0
		velocity.x = dir * _speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, _speed)

func _check_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = _jump_vel
		_set_state(State.JUMP)

func _check_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		_set_state(State.ATTACK)
		_do_attack()

# ---------------------------------------------------------------------------
# Attack
# ---------------------------------------------------------------------------

func _do_attack() -> void:
	# Damage any enemy that overlaps the sprite bounds right now.
	# A proper AttackHitbox Area2D will replace this in the full phase.
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= 55.0:
			enemy.take_damage(_damage)

	# Return to IDLE after the swing animation finishes.
	await get_tree().create_timer(0.35).timeout
	if _state == State.ATTACK:
		_set_state(State.IDLE)

# ---------------------------------------------------------------------------
# Damage reception (called by knight_enemy.gd)
# ---------------------------------------------------------------------------

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _state == State.DEAD or _inv_timer > 0.0:
		return

	health = max(0, health - amount)
	_inv_timer = INVINCIBILITY_DURATION

	# Notify the HUD (it listens via group signal).
	# TODO: emit a proper signal once HealthComponent is added.
	print("Player HP: %d / %d" % [health, max_health])

	if health == 0:
		_on_died()
		return

	if knockback != Vector2.ZERO:
		velocity = knockback
	_set_state(State.HURT)
	await get_tree().create_timer(0.3).timeout
	if _state == State.HURT:
		_set_state(State.IDLE)

# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

func _update_state_from_physics() -> void:
	if _state in [State.DEAD, State.ATTACK, State.HURT]:
		return
	if is_on_floor():
		_set_state(State.RUN if abs(velocity.x) > 10.0 else State.IDLE)
	else:
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)

func _set_state(s: State) -> void:
	if _state != s:
		_state = s

# ---------------------------------------------------------------------------
# Animation
# Note: the sprite sheet has idle, walk, attack, hurt, death.
#       Jump and fall reuse "idle" until custom frames are added.
# ---------------------------------------------------------------------------

func _update_animation() -> void:
	match _state:
		State.IDLE:            _sprite.play("idle")
		State.RUN:             _sprite.play("walk")
		State.JUMP, State.FALL: _sprite.play("idle")
		State.ATTACK:          _sprite.play("attack")
		State.HURT:            _sprite.play("hurt")
		State.DEAD:            _sprite.play("death")

# ---------------------------------------------------------------------------
# Death
# ---------------------------------------------------------------------------

func _on_died() -> void:
	_set_state(State.DEAD)
	set_collision_layer_value(1, false)
	LevelManager.on_player_death()
