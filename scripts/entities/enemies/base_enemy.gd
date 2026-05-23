## @class BaseEnemy
## @brief Shared base class for all enemy characters.
##
## Inherits from Entity and implements a generic enemy state machine:
## IDLE, PATROL, AGGRO, ATTACK, HURT, DEAD.
## Handles movement, player detection, basic melee attack, damage,
## and kill statistics updates via GameManager.
class_name BaseEnemy
extends Entity

## @enum State
## @brief Possible enemy states for the internal state machine.
enum State { IDLE, PATROL, AGGRO, ATTACK, HURT, DEAD }

## @var _state
## @brief Current state of the enemy's state machine.
var _state: State = State.PATROL

## @var character_res
## @brief Static character configuration loaded from CharacterResource (.tres).
var character_res: CharacterResource = null

## @var patrol_speed
## @brief Horizontal speed while patrolling (pixels per second).
@export var patrol_speed: float       = 40.0
## @var chase_speed
## @brief Horizontal speed while chasing the player (pixels per second).
@export var chase_speed: float        = 80.0
## @var aggro_range
## @brief Distance at which the enemy switches from PATROL to AGGRO (pixels).
@export var aggro_range: float        = 140.0
## @var lose_aggro_range
## @brief Distance at which the enemy gives up chasing and returns to PATROL (pixels).
@export var lose_aggro_range: float   = 220.0
## @var attack_range
## @brief Distance at which the enemy starts a melee attack (pixels).
@export var attack_range: float       = 35.0
## @var attack_cooldown
## @brief Minimum time between two attacks (seconds).
@export var attack_cooldown: float    = 1.4

## Sprite flashing parameters
@export var hurt_flash_count: int   = 4
@export var hurt_flash_speed: float = 0.07

## @var _dir
## @brief Current patrol direction: 1.0 = right, -1.0 = left.
var _dir: float = 1.0
## @var _player
## @brief Cached reference to the player character (BasePlayer).
var _player: BasePlayer = null
## @var _attack_timer
## @brief Remaining cooldown time before the next attack can start (seconds).
var _attack_timer: float = 0.0

## @var _sprite
## @brief Animated sprite used for playing enemy animations.
@onready var _sprite: AnimatedSprite2D = (
	$AnimatedSprite2D if has_node("AnimatedSprite2D") else null
)
## @var _ray_right
## @brief RayCast used to detect walls / edges on the right while patrolling.
@onready var _ray_right: RayCast2D = (
	$RayCastRight if has_node("RayCastRight") else null
)
## @var _ray_left
## @brief RayCast used to detect walls / edges on the left while patrolling.
@onready var _ray_left: RayCast2D = (
	$RayCastLeft if has_node("RayCastLeft") else null
)


## @brief Called when the node enters the scene tree.
## Initializes faction, group membership and defers player lookup.
func _ready() -> void:
	super._ready()
	if faction == "neutral":
		faction = "enemy"
	register_groups_from_faction()
	call_deferred("_find_player")


## @brief Finds and caches a reference to the player in the "player" group.
func _find_player() -> void:
	# get_nodes_in_group returns Array[Node], so we keep the variable untyped
	# and explicitly cast the first element to BasePlayer.
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as BasePlayer


## @brief Configures this enemy from a CharacterResource instance.
## @param res CharacterResource containing base HP/DMG/SPD values.
func set_character_resource(res: CharacterResource) -> void:
	character_res = res
	if character_res == null:
		push_error("BaseEnemy: character_res is null!")
		return

	entity_name = character_res.character_id

	# Build a stats dictionary compatible with Entity.apply_stats_from_dict().
	var stats: Dictionary = {
		GameManager.KEY_HP:    character_res.base_hp,
		GameManager.KEY_DMG:   character_res.base_dmg,
		GameManager.KEY_SPEED: character_res.base_spd,
	}
	apply_stats_from_dict(stats)


## @brief Physics step: updates state, movement, gravity, and animations.
## @param delta Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)

	# Apply gravity while not on the floor.
	if not is_on_floor():
		velocity.y += gravity * delta

	match _state:
		State.PATROL:
			_do_patrol()
		State.AGGRO:
			_do_chase()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		State.HURT:
			# Knockback is already applied when entering HURT.
			pass
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()


## @brief Handles simple back‑and‑forth patrol using raycasts for turning.
func _do_patrol() -> void:
	if _dir > 0.0 and _ray_right and _ray_right.is_colliding():
		_dir = -1.0
	elif _dir < 0.0 and _ray_left and _ray_left.is_colliding():
		_dir = 1.0

	velocity.x = _dir * patrol_speed
	if _sprite:
		_sprite.flip_h = _dir < 0.0


## @brief Handles chasing behaviour when the enemy is in AGGRO state.
func _do_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(_player.global_position)

	# Too far away → give up and return to PATROL.
	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Close enough and off cooldown → start an attack.
	if dist <= attack_range and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		_do_attack()
		return

	# Move horizontally towards the player while chasing.
	var move_dir: float = sign(_player.global_position.x - global_position.x)
	velocity.x = move_dir * chase_speed
	if _sprite:
		_sprite.flip_h = move_dir < 0.0


## @brief Checks if the enemy should switch from PATROL to AGGRO.
func _check_aggro() -> void:
	if _state != State.PATROL or _player == null:
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= aggro_range:
		_set_state(State.AGGRO)


## @brief Performs a delayed melee attack against the player if still in range.
func _do_attack() -> void:
	# Small delay to simulate a wind‑up before damage is applied.
	await get_tree().create_timer(0.25).timeout

	if _state == State.DEAD or _state == State.HURT:
		return

	if _player \
	and global_position.distance_to(_player.global_position) <= attack_range + 10.0:
		var knock_dir: float = sign(_player.global_position.x - global_position.x)
		if _player.has_method("take_damage"):
			_player.take_damage(damage, Vector2(knock_dir * 160.0, -100.0))

	_attack_timer = attack_cooldown

	if _state == State.ATTACK:
		_set_state(State.AGGRO if _player else State.PATROL)


## @brief Applies damage to this enemy and updates its state accordingly.
## @param amount Damage amount to subtract from health.
## @param knockback Optional knockback vector applied on hit.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount)

	if not is_alive:
		_set_state(State.DEAD)
		_on_died()
		return

	_set_state(State.HURT)
	_on_took_damage(amount)
	if knockback != Vector2.ZERO:
		velocity = knockback
		
	await get_tree().create_timer(0.4).timeout
	if _state != State.HURT:
			return
	_set_state(State.AGGRO if _player != null else State.PATROL)

func _on_took_damage(amount: int) -> void:
	## Default: csak logol – konkrét karakter (PlayerKnight) teheti hozzá a flash effektet.
	_flash_sprite()
	print("[BaseCharacter] Took damage: -%d | HP: %d / %d" % [amount, health, max_health])

func _flash_sprite() -> void:
	if _sprite == null:
		return

	for i in hurt_flash_count:
		_sprite.visible = false
		await get_tree().create_timer(hurt_flash_speed).timeout
		_sprite.visible = true
		await get_tree().create_timer(hurt_flash_speed).timeout

## @brief Helper to change state, prevents unnecessary re‑assignments.
## @param s New state value.
func _set_state(s: State) -> void:
	if _state != s:
		_state = s


## @brief Updates the currently played animation based on the state and velocity.
func _update_animation() -> void:
	if _sprite == null:
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


## @brief Called once when the enemy dies.
## Updates global kill statistics and removes the node after a short delay.
func _on_died() -> void:
	if GameManager != null:
		var stats: Dictionary = GameManager.runtime_data.get(
			GameManager.KEY_STATISTICS, {}
		)
		stats[GameManager.KEY_KILLS] = stats.get(GameManager.KEY_KILLS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats

	await get_tree().create_timer(0.7).timeout
	queue_free()
