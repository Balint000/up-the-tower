## Projectile fired by [PlayerArcher].
##
## Compatible with [method BasePlayer.spawn_projectile]: accepts a
## direction sign instead of a full direction vector. Travels horizontally
## and removes itself after [member max_range] pixels or on first collision.
class_name PlayerArrow
extends Area2D

## Current velocity vector (pixels per second). Set by [method setup].
var _velocity: Vector2 = Vector2.ZERO
## Damage dealt on a successful hit.
var _damage: int = 10
## Scene-tree group name of valid targets (e.g. [code]"enemies"[/code]).
var _target_group: String = "enemies"
## Default travel speed (pixels per second).
@export var arrow_speed: float = 300.0
## World position at the time of firing, used to calculate travelled distance.
var _start_position: Vector2 = Vector2.ZERO
## Maximum flight distance before the arrow is destroyed (pixels).
@export var max_range: float = 200.0


## Initialises the arrow to be compatible with [method BasePlayer.spawn_projectile].
## [param from] World-space spawn position.
## [param direction_sign] [code]1.0[/code] = right, [code]-1.0[/code] = left.
## [param dmg] Damage to apply on hit.
## [param target_group] Scene-tree group of valid targets.
func setup(from: Vector2, direction_sign: float, dmg: int, target_group: String = "enemies") -> void:
	global_position = from
	_damage = dmg
	_target_group = target_group
	_velocity = Vector2(direction_sign * arrow_speed, 0.0)
	rotation = _velocity.angle()


## Records the spawn position and connects the body-entered signal.
func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)


## Advances position by [member _velocity] * [param delta] each frame.
## Destroys the arrow once it has travelled [member max_range] pixels.
func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if global_position.distance_to(_start_position) >= max_range:
		queue_free()


## Deals damage to any node in [member _target_group] on contact.
## Also destroys the arrow on contact with [TileMapLayer] or [StaticBody2D].
## [param body] The colliding [Node].
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group(_target_group):
		if body.has_method("take_damage"):
			body.take_damage(_damage, _velocity.normalized() * 80.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
