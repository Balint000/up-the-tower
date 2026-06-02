class_name FireballAtk
extends Area2D

## (px/s).
var _velocity: Vector2 = Vector2.ZERO

## Damage
var _damage: int = 10

## Target group name
var _target_group: String = "enemies"

## Start positon for max range calculation
var _start_position: Vector2 = Vector2.ZERO

## Traveling speed
@export var fireball_speed: float = 180.0

## Maximum range in pixel
@export var max_range: float = 120.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var _direction_sign: float = 1.0

## Initialize fireball
## @param from Start position (Vector2).
## @param direction_sign Direction: 1.0 = right, -1.0 = left.
## @param dmg Damage.
## @param target_group Target group name.
func setup(from: Vector2, direction_sign: float, dmg: int, target_group: String = "enemies") -> void:
	_direction_sign = direction_sign
	global_position = from
	_damage = dmg
	_target_group = target_group
	_velocity = Vector2(direction_sign * fireball_speed, 0.0)
	
	if _sprite:
		_sprite.flip_h = _direction_sign < 0.0
		_sprite.play("fly")

func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)

	if _sprite:
		_sprite.flip_h = _direction_sign < 0.0
		_sprite.play("attack")


## Updates the position and checks the max range.
## delta Frame time in seconds
func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if global_position.distance_to(_start_position) >= max_range:
		queue_free()


## Hit: damage
## @param body Collision node
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group(_target_group):
		if body.has_method("take_damage"):
			body.take_damage(_damage, _velocity.normalized() * 80.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
