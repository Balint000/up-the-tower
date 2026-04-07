## player.gd
## Attaches to MainCharacter (CharacterBody2D).
##
## Characters share this script — their stats come from Game_Manager.player_data.
## The special ability (Shift) is a stub here; each character's full ability
## will be implemented in the full phase.
##
## Required child nodes:
##   AnimatedSprite2D   — sprite and animations
##   HealthComponent    — hp tracking
##   AttackHitbox       — Area2D, disabled except during swing

extends CharacterBody2D

# ---------------------------------------------------------------------------
# Tunables (base values; overridden by character stats from GameManager)
# ---------------------------------------------------------------------------

@export var base_speed: float       = 180.0
@export var base_jump_velocity: float = -400.0
@export var base_damage: int        = 20

## Coyote time: lets the player jump briefly after walking off a ledge.
@export var coyote_time: float      = 0.12

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }
var _state := State.IDLE

# ---------------------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------------------

@onready var _sprite:      AnimatedSprite2D = $AnimatedSprite2D
@onready var _health:      HealthComponent  = $HealthComponent
@onready var _atk_hitbox:  Area2D           = $AttackHitbox

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

var _speed: float
var _jump_vel: float
var _damage: int
var _coyote_left: float = 0.0
var _was_on_floor: bool = false
var _facing_right: bool = true

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("player")
	_apply_character_stats()
	_health.died.connect(_on_died)
	_atk_hitbox.monitoring = false

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_tick_coyote(delta)

	match _state:
		State.IDLE, State.RUN:
			_move()
			_check_jump()
			_check_attack()
		State.JUMP, State.FALL:
			_move()
			_check_jump()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, _speed)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, _speed * 3.0 * delta)
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_refresh_state()
	_play_animation()
	_was_on_floor = is_on_floor()

# ---------------------------------------------------------------------------
# Character stats
# ---------------------------------------------------------------------------

## Pull speed / hp / damage from GameManager so character choice matters.
func _apply_character_stats() -> void:
	var pd := GameManager.player_data
	# Multiply base values by the stat multipliers stored in GameManager.
	_speed    = base_speed        * pd.get(GameManager.KEY_SPEED, 1.0)
	_jump_vel = base_jump_velocity
	_damage   = roundi(base_damage * pd.get(GameManager.KEY_DMG,   1.0))

	var hp_mult: float = pd.get(GameManager.KEY_HP, 1.0)
	_health.max_health  = roundi(100.0 * hp_mult)
	_health.reset()

# ---------------------------------------------------------------------------
# Gravity & coyote
# ---------------------------------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _tick_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_left = coyote_time
	elif is_on_floor():
		_coyote_left = 0.0
	else:
		_coyote_left = max(0.0, _coyote_left - delta)

# ---------------------------------------------------------------------------
# Input handlers
# ---------------------------------------------------------------------------

func _move() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		_facing_right = dir > 0.0
		_sprite.flip_h = not _facing_right
		velocity.x = dir * _speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, _speed)

func _check_jump() -> void:
	var can_jump := is_on_floor() or _coyote_left > 0.0
	if Input.is_action_just_pressed("ui_accept") and can_jump:
		velocity.y = _jump_vel
		_coyote_left = 0.0
		_set_state(State.JUMP)

func _check_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		_set_state(State.ATTACK)
		_do_attack()

func _check_special() -> void:
	# Stub — full character abilities land in the next phase.
	if Input.is_action_just_pressed("special"):
		var character := GameManager.runtime_data.get(GameManager.KEY_SELECTED_CHARACTER, "knight")
		print("Special pressed — character: ", character, " (not yet implemented)")

# ---------------------------------------------------------------------------
# Attack
# ---------------------------------------------------------------------------

func _do_attack() -> void:
	_atk_hitbox.monitoring = true
	await get_tree().create_timer(0.25).timeout
	_atk_hitbox.monitoring = false
	if _state == State.ATTACK:
		_set_state(State.IDLE)

# ---------------------------------------------------------------------------
# Damage reception (called by enemy scripts)
# ---------------------------------------------------------------------------

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _state == State.DEAD:
		return
	_health.take_damage(amount)
	if not _health.is_dead():
		velocity = knockback
		_set_state(State.HURT)
		await get_tree().create_timer(0.3).timeout
		if _state == State.HURT:
			_set_state(State.IDLE)

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

func _refresh_state() -> void:
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
# ---------------------------------------------------------------------------

func _play_animation() -> void:
	match _state:
		State.IDLE:   _sprite.play("idle")
		State.RUN:    _sprite.play("run")
		State.JUMP:   _sprite.play("jump")
		State.FALL:   _sprite.play("fall")
		State.ATTACK: _sprite.play("attack")
		State.HURT:   _sprite.play("hurt")
		State.DEAD:   _sprite.play("dead")

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_died() -> void:
	_set_state(State.DEAD)
	set_collision_layer_value(1, false)
	GameManager.on_player_death()
