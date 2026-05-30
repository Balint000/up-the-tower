## @class PlayerArrow
## @brief A PlayerArcher által kilőtt nyíl projektil.
##
## Area2D alapú lövedék, kompatibilis a BasePlayer.spawn_projectile() hívással.
## setup() szignatúra: (from, direction_sign, dmg, target_group).
## Ütközéskor sebzi a célcsoport entitásait, falnak ütközve eltűnik.
class_name PlayerArrow
extends Area2D

## @var _velocity
## @brief Aktuális sebességvektor (px/s).
var _velocity: Vector2 = Vector2.ZERO

## @var _damage
## @brief Okozandó sebzés.
var _damage: int = 10

## @var _target_group
## @brief A célcsoport neve (pl. "enemies").
var _target_group: String = "enemies"

## @export arrow_speed
## @brief Nyíl alapértelmezett sebessége (px/s).
@export var arrow_speed: float = 300.0

## @var _start_position
## @brief Kiindulási pozíció a max range számításhoz.
var _start_position: Vector2 = Vector2.ZERO

## @export max_range
## @brief Maximális repülési távolság pixelben.
@export var max_range: float = 200.0


## @brief Inicializálja a nyilat a BasePlayer.spawn_projectile() hívásával kompatibilis módon.
## @param from Kiindulási globális pozíció (Vector2).
## @param direction_sign Irány előjele: 1.0 = jobb, -1.0 = bal.
## @param dmg Okozandó sebzés (int).
## @param target_group A cél csoport neve (String, pl. "enemies").
func setup(from: Vector2, direction_sign: float, dmg: int, target_group: String = "enemies") -> void:
	global_position = from
	_damage         = dmg
	_target_group   = target_group
	_velocity       = Vector2(direction_sign * arrow_speed, 0.0)
	rotation        = _velocity.angle()


## @brief Csatlakoztatja az ütközés-jelzőket, 3 másodperc után auto-destroy.
func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)


## @brief Frissíti a nyíl pozícióját minden frame-ben.
## @param delta Frame idő másodpercekben.
func _physics_process(delta: float) -> void:
	position += _velocity * delta
	if global_position.distance_to(_start_position) >= max_range:
		queue_free()


## @brief Ütközés kezelése: csoport-alapú ellenőrzés és sebzés alkalmazása.
## @param body Az ütköző Node.
func _on_body_entered(body: Node) -> void:
	if body is Node2D and body.is_in_group(_target_group):
		if body.has_method("take_damage"):
			body.take_damage(_damage, _velocity.normalized() * 80.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
