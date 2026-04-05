## knight_enemy.gd
## Replaces the stub patrol script on knightEnemy.tscn.
## Uses the existing RayCastRight / RayCastLeft nodes for wall detection.
## Player detection is distance-based (no Area2D needed in the scene).
##
## States:
##   PATROL  — walks back and forth, turns at walls/ledges
##   AGGRO   — chases the player
##   ATTACK  — stops and swings when close enough
##   HURT    — brief stun after taking a hit
##   DEAD    — plays death animation then removes itself

extends CharacterBody2D

# ---------------------------------------------------------------------------
# Tunables
# ---------------------------------------------------------------------------

@export var patrol_speed: float    = 40.0
@export var chase_speed: float     = 80.0
@export var health: int            = 60
@export var damage: int            = 15
@export var aggro_range: float     = 140.0  # pixels — enter chase
@export var lose_aggro_range: float = 220.0  # pixels — give up chase
@export var attack_range: float    = 50.0   # pixels — start swinging
@export var attack_cooldown: float = 1.4    # seconds between swings

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

enum State { PATROL, AGGRO, ATTACK, HURT, DEAD }
var _state: State = State.PATROL

# ---------------------------------------------------------------------------
# Node refs (same names as in knightEnemy.tscn)
# ---------------------------------------------------------------------------

@onready var _sprite:     AnimatedSprite2D = $AnimatedSprite2D
@onready var _ray_right:  RayCast2D        = $RayCastRight
@onready var _ray_left:   RayCast2D        = $RayCastLeft

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

var _dir: float = 1.0               # patrol direction: 1 = right, -1 = left
var _player: CharacterBody2D = null
var _atk_timer: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("enemies")
	# Cache a reference to the player once the scene is ready.
	# Using call_deferred so the player node is guaranteed to exist.
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as CharacterBody2D

func _physics_process(delta: float) -> void:
	_atk_timer = max(0.0, _atk_timer - delta)

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	match _state:
		State.PATROL: _do_patrol()
		State.AGGRO:  _do_chase()
		State.ATTACK: velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		State.HURT:   pass   # velocity set in take_damage; decays here
		State.DEAD:   velocity = Vector2.ZERO

	move_and_slide()
	_update_animation()
	_check_aggro_range()

# ---------------------------------------------------------------------------
# PATROL
# ---------------------------------------------------------------------------

func _do_patrol() -> void:
	# Turn around when the ray in the current direction hits a wall.
	if _dir > 0 and _ray_right.is_colliding():
		_dir = -1.0
	elif _dir < 0 and _ray_left.is_colliding():
		_dir = 1.0

	velocity.x = _dir * patrol_speed
	_sprite.flip_h = _dir < 0.0

# ---------------------------------------------------------------------------
# AGGRO / CHASE
# ---------------------------------------------------------------------------

func _do_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	if dist <= attack_range and _atk_timer <= 0.0:
		_set_state(State.ATTACK)
		_do_attack()
		return

	var move_dir = sign(_player.global_position.x - global_position.x)
	velocity.x = move_dir * chase_speed
	_sprite.flip_h = move_dir < 0.0

## Check aggro from PATROL state (called every physics frame).
func _check_aggro_range() -> void:
	if _state != State.PATROL or _player == null:
		return
	if global_position.distance_to(_player.global_position) <= aggro_range:
		_set_state(State.AGGRO)

# ---------------------------------------------------------------------------
# ATTACK
# ---------------------------------------------------------------------------

func _do_attack() -> void:
	# Deal damage if the player is still in range when the swing lands.
	await get_tree().create_timer(0.25).timeout

	if _state == State.DEAD:
		return

	if _player and global_position.distance_to(_player.global_position) <= attack_range + 10.0:
		var knockback_dir = sign(_player.global_position.x - global_position.x)
		_player.take_damage(damage, Vector2(knockback_dir * 160.0, -100.0))

	_atk_timer = attack_cooldown

	if _state == State.ATTACK:
		_set_state(State.AGGRO if _player else State.PATROL)

# ---------------------------------------------------------------------------
# Damage reception (called by playerKnight.gd)
# ---------------------------------------------------------------------------

func take_damage(amount: int) -> void:
	if _state == State.DEAD:
		return

	health = max(0, health - amount)
	print("Enemy HP: %d" % health)

	if health == 0:
		_on_died()
		return

	_set_state(State.HURT)
	# Brief knockback away from the player.
	if _player:
		velocity.x = -sign(_player.global_position.x - global_position.x) * 120.0
	await get_tree().create_timer(0.25).timeout
	if _state == State.HURT:
		_set_state(State.AGGRO if _player else State.PATROL)

# ---------------------------------------------------------------------------
# State helper
# ---------------------------------------------------------------------------

func _set_state(s: State) -> void:
	if _state != s:
		_state = s

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _update_animation() -> void:
	match _state:
		State.PATROL:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.AGGRO:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.ATTACK:
			_sprite.play("attack")
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")

# ---------------------------------------------------------------------------
# Death
# ---------------------------------------------------------------------------

func _on_died() -> void:
	_set_state(State.DEAD)
	set_collision_layer_value(1, false)
	GameManager.runtime_data[GameManager.KEY_STATISTICS][GameManager.KEY_KILLS] += 1
	await get_tree().create_timer(0.7).timeout
	queue_free()
