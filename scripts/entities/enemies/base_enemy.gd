## Shared base class for all enemy characters.
##
## Inherits from [Entity] and implements a generic finite state machine
## with states: IDLE, PATROL, AGGRO, ATTACK, HURT, DEAD.
## Handles movement, player detection, basic melee attacks, damage reactions,
## sprite-flash feedback, and kill-counter updates via [GameManager].
##
## Concrete enemy types (e.g. [ArcherEnemy], [ChargerEnemy]) extend this class
## and override specific methods to add unique behaviour.
class_name BaseEnemy
extends Entity

## Possible states for the internal finite state machine.
enum State { IDLE, PATROL, AGGRO, ATTACK, HURT, DEAD, JUMP }

## Currently active state of the enemy's state machine.
var _state: State = State.PATROL

## Static character configuration loaded from a [CharacterResource] (.tres).
## Assigned by [method set_character_resource] when the enemy is spawned via [EnemySpawner].
var character_res: CharacterResource = null

## Horizontal movement speed while patrolling (pixels per second).
@export var patrol_speed: float = 40.0
## Horizontal movement speed while chasing the player (pixels per second).
@export var chase_speed: float = 80.0
## Detection radius: the player entering this range triggers AGGRO (pixels).
@export var aggro_range: float = 140.0
## Give-up radius: the player leaving this range causes a return to PATROL (pixels).
@export var lose_aggro_range: float = 220.0
## Melee attack initiation distance (pixels).
@export var attack_range: float = 30.0
## Minimum time between two consecutive melee attacks (seconds).
@export var attack_cooldown: float = 1.4

## Number of visibility blinks produced by the hit-flash effect.
@export var hurt_flash_count: int = 4
## Duration of each individual blink in the hit-flash effect (seconds).
@export var hurt_flash_speed: float = 0.07

## Current patrol direction: [code]1.0[/code] = right, [code]-1.0[/code] = left.
var _dir: float = 1.0
## Cached reference to the player. Populated by [method _find_player].
var _player: BasePlayer = null
## Remaining cooldown before the next melee attack is permitted (seconds).
var _attack_timer: float = 0.0

## Animated sprite for enemy animations. Resolved by node name at runtime.
@onready var _sprite: AnimatedSprite2D = (
	$AnimatedSprite2D if has_node("AnimatedSprite2D") else null
)
## Right-facing [RayCast2D] that detects walls and ledge edges during patrol.
@onready var _ray_right: RayCast2D = (
	$RayCastRight if has_node("RayCastRight") else null
)
## Left-facing [RayCast2D] that detects walls and ledge edges during patrol.
@onready var _ray_left: RayCast2D = (
	$RayCastLeft if has_node("RayCastLeft") else null
)


## Sets the faction to [code]"enemy"[/code] when still [code]"neutral"[/code],
## registers the node in the [code]"enemies"[/code] scene-tree group, and
## defers a player look-up via [method _find_player].
func _ready() -> void:
	super._ready()
	if faction == "neutral":
		faction = "enemy"
	register_groups_from_faction()
	call_deferred("_find_player")


## Queries the [code]"player"[/code] scene-tree group and caches the first
## result in [member _player]. Deferred from [method _ready] so that the
## player node is guaranteed to be in the tree before the search runs.
func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as BasePlayer


## Configures this enemy from a [CharacterResource] instance.
## Copies [member CharacterResource.character_id] as the entity name, then
## applies HP, DMG, and SPD via [method Entity.apply_stats_from_dict].
## [param res] The [CharacterResource] containing the base stat values.
func set_character_resource(res: CharacterResource) -> void:
	character_res = res
	if character_res == null:
		push_error("BaseEnemy: character_res is null!")
		return

	entity_name = character_res.character_id

	var stats: Dictionary = {
		GameManager.KEY_HP: character_res.base_hp,
		GameManager.KEY_DMG: character_res.base_dmg,
		GameManager.KEY_SPEED: character_res.base_spd,
	}
	apply_stats_from_dict(stats)


## Physics update: advances the state machine, applies gravity, moves the
## character body, checks aggro transitions, and refreshes the animation.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	match _state:
		State.PATROL:
			_do_patrol()
		State.AGGRO:
			_do_chase()
		State.ATTACK:
			# Decelerate horizontally during the attack wind-up pause.
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		State.HURT:
			# Knockback velocity was already set when HURT was entered; nothing to do here.
			pass
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()


## Back-and-forth patrol movement using raycasts.
## Reverses [member _dir] when [member _ray_right] or [member _ray_left]
## reports a collision (wall or missing floor ahead).
func _do_patrol() -> void:
	if _dir > 0.0 and _ray_right and _ray_right.is_colliding():
		_dir = -1.0
	elif _dir < 0.0 and _ray_left and _ray_left.is_colliding():
		_dir = 1.0

	velocity.x = _dir * patrol_speed
	if _sprite:
		_sprite.flip_h = _dir < 0.0


## Chase behaviour while in AGGRO state.
## Returns to PATROL when the player moves beyond [member lose_aggro_range].
## Transitions to ATTACK when within [member attack_range] and the cooldown expires.
func _do_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	if dist <= attack_range and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		_do_attack()
		return

	var move_dir: float = sign(_player.global_position.x - global_position.x)
	velocity.x = move_dir * chase_speed
	if _sprite:
		_sprite.flip_h = move_dir < 0.0


## Checks every frame whether the enemy should switch from PATROL to AGGRO.
## The transition fires when the player is within [member aggro_range].
## Skipped entirely if already in a non-PATROL state or if [member _player] is null.
func _check_aggro() -> void:
	if _state != State.PATROL or _player == null:
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= aggro_range:
		_set_state(State.AGGRO)


## Executes a delayed melee attack against the player.
## Waits 0.25 s as a wind-up, then applies [member Entity.damage] with a
## directional knockback vector if the player is still within range.
## Resets [member _attack_timer] and returns the enemy to AGGRO (or PATROL).
func _do_attack() -> void:
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


## Receives damage, optionally applies knockback, and manages state transitions.
## Delegates health reduction to [method Entity.take_damage].
## On death, calls [method _on_died]; otherwise enters HURT for 0.4 s before
## returning to AGGRO or PATROL.
## [param amount] Damage amount to subtract from health.
## [param knockback] Optional impulse vector applied to [member velocity] on hit.
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

## Called immediately after a non-lethal hit.
## Triggers the sprite-flash effect and prints a debug message to the output log.
## Subclasses may override to add class-specific hit reactions.
## [param amount] The damage amount that was applied.
func _on_took_damage(amount: int) -> void:
	_flash_sprite()
	print("[Enemy] Took damage: -%d | HP: %d / %d" % [amount, health, max_health])

## Blinks the enemy sprite [member hurt_flash_count] times at [member hurt_flash_speed]
## intervals to visually confirm a successful hit to the player.
func _flash_sprite() -> void:
	if _sprite == null:
		return

	for i in hurt_flash_count:
		_sprite.visible = false
		await get_tree().create_timer(hurt_flash_speed).timeout
		_sprite.visible = true
		await get_tree().create_timer(hurt_flash_speed).timeout

## Transitions to state [param s] only if it differs from the current state,
## preventing redundant assignments and potential signal noise.
func _set_state(s: State) -> void:
	if _state != s:
		_state = s


## Plays the appropriate animation clip based on the current state and velocity.
## Chooses between [code]"walk"[/code] and [code]"idle"[/code] while moving/standing
## in PATROL or AGGRO; plays dedicated clips for ATTACK, HURT, and DEAD.
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


## Called once when health reaches zero (from [method take_damage]).
## Increments the kill counter in [member GameManager.runtime_data] under
## [constant GameManager.KEY_KILLS], then removes this node after a 0.7-second
## delay to allow the death animation to finish.
func _on_died() -> void:
	if GameManager != null:
		var stats: Dictionary = GameManager.runtime_data.get(
			GameManager.KEY_STATISTICS, {}
		)
		stats[GameManager.KEY_KILLS] = stats.get(GameManager.KEY_KILLS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats

	await get_tree().create_timer(0.7).timeout
	queue_free()
