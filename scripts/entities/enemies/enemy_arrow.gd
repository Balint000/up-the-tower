## Projectile fired by [ArcherEnemy].
##
## [Area2D]-based flying arrow. Initialise with [method setup] before adding
## to the scene. On collision it deals damage to [BasePlayer] entities and
## disappears on contact with any [TileMapLayer] or [StaticBody2D].
## Auto-destroys after 4 seconds if nothing is hit.
class_name EnemyArrow
extends Area2D

## Current velocity vector (pixels per second). Set by [method setup].
var _velocity: Vector2 = Vector2.ZERO

## Damage to deal on a successful hit with the player.
var _damage: int = 10

## When [code]true[/code], a weak downward gravity is applied every frame,
## giving the arrow a curved arc trajectory.
@export var use_gravity: bool = false

## Gravity scale applied when [member use_gravity] is [code]true[/code] (px/s²).
@export var gravity_scale: float = 60.0


## Initialises position, velocity, damage, and rotation.
## Must be called before [method Node._ready] adds the arrow to the scene,
## or immediately after [method PackedScene.instantiate].
## [param from] World-space spawn position.
## [param direction] Normalised direction vector the arrow should travel.
## [param dmg] Damage to apply on player hit.
## [param speed] Travel speed in pixels per second (default 220).
func setup(from: Vector2, direction: Vector2, dmg: int, speed: float = 220.0) -> void:
	global_position = from
	_velocity = direction * speed
	_damage = dmg
	rotation = direction.angle()


## Connects collision signals and schedules an auto-destroy timer (4 seconds).
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		queue_free()


## Moves the arrow every physics frame. If [member use_gravity] is enabled,
## applies [member gravity_scale] to the vertical component and updates the
## rotation to match the new flight angle.
## [param delta] Frame time in seconds.
func _physics_process(delta: float) -> void:
	if use_gravity:
		_velocity.y += gravity_scale * delta
		rotation = _velocity.angle()
	position += _velocity * delta


## Handles collisions with physics bodies.
## Deals [member _damage] to a [BasePlayer] and then frees the arrow.
## Also frees the arrow on contact with [TileMapLayer] or [StaticBody2D] (walls/floors).
## [param body] The colliding [Node].
func _on_body_entered(body: Node) -> void:
	if body is BasePlayer:
		body.take_damage(_damage, _velocity.normalized() * 100.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()


## Handles collisions with other [Area2D] nodes (e.g. a player shield).
## Extend this method to implement shield or parry interactions.
## [param _area] The colliding [Area2D].
func _on_area_entered(_area: Area2D) -> void:
	pass
