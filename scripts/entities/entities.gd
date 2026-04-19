extends CharacterBody2D
class_name Entity
## Általános entitás ősosztály.
## Minden aktív karakter (játszható és ellenfél) ezt örökölje.
## A konkrét statokat a GameManager/DataDb tölti be.

## Alap statok
var max_health: int = 1
var health: int = max_health
var is_alive: bool = true

var damage: int = 1
var move_speed: float = 100.0
var gravity: float = 1200.0

## Az entitás azonosítására / csoportosítására
var entity_name: String = ""
var faction: String = "neutral"  ## "player", "enemy", "neutral", stb.

signal died(entity: Entity)
signal health_changed(entity: Entity, old_value: int, new_value: int)

func _ready() -> void:
	## Leszármazottak (pl. PlayerKnight, Enemy) innen indulnak.
	pass


func apply_stats_from_dict(stats: Dictionary) -> void:
	## GameManager.player_data és/vagy karakter resource alapján tölti fel a statokat.
	## Kulcsok a GameManager konstansai szerint.
	if stats.has(GameManager.KEY_HP):
		max_health = int(stats[GameManager.KEY_HP])
		health = max_health

	if stats.has(GameManager.KEY_DMG):
		damage = int(stats[GameManager.KEY_DMG])

	if stats.has(GameManager.KEY_SPEED):
		move_speed = float(stats[GameManager.KEY_SPEED])


func take_damage(amount: int) -> void:
	## Sebzés alkalmazása az entitásra.
	if not is_alive:
		return

	var old_health := health
	health = max(health - amount, 0)
	emit_signal("health_changed", self, old_health, health)

	if health == 0:
		die()


func heal(amount: int) -> void:
	## Gyógyítás az entitáson.
	if not is_alive:
		return

	var old_health := health
	health = min(health + amount, max_health)
	emit_signal("health_changed", self, old_health, health)


func die() -> void:
	## Alap halálkezelés – később felüldefiniálható.
	if not is_alive:
		return

	is_alive = false
	emit_signal("died", self)
	queue_free()
