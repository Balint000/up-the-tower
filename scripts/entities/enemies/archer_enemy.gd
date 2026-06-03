## Ranged enemy that attacks the player by firing [EnemyArrow] projectiles.
##
## Maintains a preferred standoff distance from the player: backs away when
## the player closes in and advances when too far. Once at the right distance
## it stops and fires arrows on a cooldown.
##
## [member arrow_scene] must be assigned in the editor. Without it the enemy
## logs a warning and skips firing but continues to patrol and chase normally.
class_name ArcherEnemy
extends BaseEnemy

## Ideal distance to maintain from the player (pixels).
## The enemy tolerates ±25 px deviation before repositioning.
@export var preferred_distance: float = 130.0

## Damage dealt by each fired arrow. Overrides the base [member Entity.damage].
@export var arrow_damage: int = 12

## Minimum time between consecutive shots (seconds).
@export var shoot_cooldown: float = 2.0

## Travel speed of the fired arrow (pixels per second).
@export var arrow_speed: float = 220.0

## [PackedScene] of the [EnemyArrow] to instantiate on each shot.
## Must be assigned in the editor; the enemy will not fire if this is null.
@export var arrow_scene: PackedScene = null

## Remaining time before the next shot is allowed (seconds).
var _shoot_timer: float = 0.0

var _post_shoot_timer: float = 0.0


## Sets archer-appropriate [member BaseEnemy.attack_range] and
## [member BaseEnemy.aggro_range], then calls [method BaseEnemy._ready].
func _ready() -> void:
	super._ready()
	attack_range = preferred_distance + 20.0
	aggro_range = 180.0


## Physics update: runs the archer state machine, manages shoot and attack
## timers, applies gravity, moves the body, and refreshes animations.
## Overrides [method BaseEnemy._physics_process] to add the ranged-attack branch.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)
	_shoot_timer  = max(0.0, _shoot_timer  - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	match _state:
		State.PATROL: _do_patrol()
		State.AGGRO:  _do_archer_movement()
		State.ATTACK:
			# Decelerate while standing still to shoot.
			if _shoot_timer <= 0.0 and _post_shoot_timer <= 0.0:
				_shoot_arrow()
				_shoot_timer = shoot_cooldown
				_post_shoot_timer = 0.5
			if _post_shoot_timer > 0.0:
				_post_shoot_timer -= delta
				if _post_shoot_timer <= 0.0:
					_set_state(State.AGGRO)
		State.HURT: pass
		State.DEAD: velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()


## Archer-specific AGGRO movement: keeps the enemy at [member preferred_distance].
## Retreats if the player is closer than [code]preferred_distance - 25[/code],
## advances if farther than [code]preferred_distance + 25[/code], and
## transitions to ATTACK when exactly in the sweet spot.
func _do_archer_movement() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Player too close — back away.
	if dist < preferred_distance - 25.0:
		var away = sign(global_position.x - _player.global_position.x)
		velocity.x = away * chase_speed
		if _sprite:
			_sprite.flip_h = away < 0.0
		return

	# Player too far — close in to shooting distance.
	if dist > preferred_distance + 25.0:
		var toward = sign(_player.global_position.x - global_position.x)
		velocity.x = toward * patrol_speed
		if _sprite:
			_sprite.flip_h = toward < 0.0
		return

	# Correct distance — stop and enter ATTACK to begin firing.
	velocity.x = move_toward(velocity.x, 0.0, chase_speed)
	_set_state(State.ATTACK)


## Instantiates an [EnemyArrow] and launches it toward the player's position.
## The arrow is added directly to the root scene so it survives if this
## enemy is freed. Logs a warning and returns early if [member arrow_scene] is null.
func _shoot_arrow() -> void:
	if _player == null:
		return
	if arrow_scene == null:
		push_warning("ArcherEnemy: arrow_scene is not set! Assign it in the editor.")
		return

	var dir := (_player.global_position - global_position).normalized()
	var arrow := arrow_scene.instantiate()
	if arrow.has_method("setup"):
		arrow.setup(global_position, dir, arrow_damage, arrow_speed)  # Vector2, tökéletes
	get_tree().get_current_scene().add_child(arrow)
