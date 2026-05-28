## @class EnemyArrow
## @brief Repülő nyíl projektil, amelyet az ArcherEnemy lő ki.
##
## Area2D alapú lövedék; setup() hívással inicializálható.
## Ütközéskor sebzi a player faction entitásokat, falnak ütközve
## eltűnik. 4 másodperc után automatikusan megsemmisül.
class_name EnemyArrow
extends Area2D

## @var _velocity
## @brief Aktuális sebességvektor (px/s), setup()-ban kerül beállításra.
var _velocity: Vector2 = Vector2.ZERO

## @var _damage
## @brief A nyíl által okozott sebzés mértéke.
var _damage: int = 10

## @export use_gravity
## @brief Ha igaz, a nyílra gyengített gravitáció hat (ívelt röppályát ad).
@export var use_gravity: bool = false

## @export gravity_scale
## @brief Gravitációs szorzó (csak use_gravity = true esetén aktív).
@export var gravity_scale: float = 60.0


## @brief Inicializálja a nyilat pozícióval, iránnyal, sebzéssel és sebességgel.
## @param from Kiindulási globális pozíció (Vector2).
## @param direction Normalizált irányvektor (Vector2).
## @param dmg Okozandó sebzés (int).
## @param speed Repülési sebesség px/s-ban (float, alapértelmezett 220.0).
func setup(from: Vector2, direction: Vector2, dmg: int, speed: float = 220.0) -> void:
	global_position = from
	_velocity       = direction * speed
	_damage         = dmg
	rotation        = direction.angle()


## @brief Csatlakoztatja az ütközés-jelzőket és beállít egy auto-destroy timert.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		queue_free()


## @brief Frissíti a nyíl pozícióját és opcionálisan alkalmaz gravitációt.
## @param delta Frame idő másodpercekben.
func _physics_process(delta: float) -> void:
	if use_gravity:
		_velocity.y += gravity_scale * delta
		rotation = _velocity.angle()
	position += _velocity * delta


## @brief Ütközés kezelése fizikai testekkel (player, falak, padló).
## @param body Az ütköző Node.
func _on_body_entered(body: Node) -> void:
	if body is BasePlayer:
		body.take_damage(_damage, _velocity.normalized() * 100.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()


## @brief Ütközés kezelése más Area2D-kkel (pl. shield – kibővíthető).
## @param _area Az ütköző Area2D.
func _on_area_entered(_area: Area2D) -> void:
	pass
