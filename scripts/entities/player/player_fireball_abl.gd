class_name FireballAbl
extends Area2D

## @var _velocity
## @brief Aktuális sebességvektor (px/s).
var _velocity: Vector2 = Vector2.ZERO

## @var _damage
## @brief Okozandó sebzés.
var _damage: int = 20

## @var _target_group
## @brief A célcsoport neve.
var _target_group: String = "enemies"

## @var _start_position
## @brief Kiindulási pozíció a max range számításhoz.
var _start_position: Vector2 = Vector2.ZERO

## @export fireball_speed
## @brief Nagy tűzgolyó repülési sebessége (px/s) – lassabb mint a mini.
@export var fireball_speed: float = 140.0

## @export max_range
## @brief Maximális hatótávolság pixelben – nagyobb mint a mini.
@export var max_range: float = 200.0

## @export knockback_force
## @brief Ütközéskor alkalmazott knockback erő.
@export var knockback_force: float = 260.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## @brief Inicializálja a nagy tűzgolyót.
## @param from Kiindulási globális pozíció (Vector2).
## @param direction_sign Irány előjele: 1.0 = jobb, -1.0 = bal.
## @param dmg Okozandó sebzés (int).
## @param target_group A cél csoport neve (String).
func setup(from: Vector2, direction_sign: float, dmg: int, target_group: String = "enemies") -> void:
	global_position = from
	_damage         = dmg
	_target_group   = target_group
	_velocity       = Vector2(direction_sign * fireball_speed, 0.0)
	# Irány beállítása: bal felé flip, jobb felé normál
	if _sprite:
		_sprite.flip_h = direction_sign < 0.0

func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)
	# Animáció indítása
	if _sprite:
		_sprite.play("fly")


## @brief Frissíti a pozíciót és ellenőrzi a max range-t.
## @param delta Frame idő másodpercekben.
func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if global_position.distance_to(_start_position) >= max_range:
		queue_free()


## @brief Ütközés kezelése: sebzés + nagyobb knockback + eltűnés.
## @param body Az ütköző Node.
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group(_target_group):
		if body.has_method("take_damage"):
			body.take_damage(_damage, _velocity.normalized() * knockback_force)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
