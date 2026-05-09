extends CharacterBody2D
class_name Entity
## Általános entitás ősosztály.
## Minden aktív karakter (játszható és ellenfél) ezt örökölje.
## A konkrét statokat a GameManager/DataDb tölti be.

# ---------------------------------------------------------------------------
# Alap statok
# ---------------------------------------------------------------------------
var max_health: int   = 1
var health: int       = max_health
var is_alive: bool    = true
var damage: int       = 1
var move_speed: float = 100.0
var gravity: float    = 1200.0

## Azonosítás / csoportosítás
var entity_name: String = ""
var faction: String     = "neutral"   # "player" | "enemy" | "neutral"

# ---------------------------------------------------------------------------
# Egységes signalok
# ---------------------------------------------------------------------------
## HP vagy más stat megváltozott → HUD, inventory frissítéshez
signal stats_changed(entity: Entity)
## Csak BasePlayer leszármazottak emelik ki → LevelManager / HUD értesítéshez.
## Ellenségek NEM emitálják.
signal player_died(entity: Entity)

# ---------------------------------------------------------------------------
# Életciklus
# ---------------------------------------------------------------------------
func _ready() -> void:
	pass

# ---------------------------------------------------------------------------
# Csoportok
# ---------------------------------------------------------------------------
func register_groups_from_faction() -> void:
	match faction:
		"player": add_to_group("player")
		"enemy":  add_to_group("enemies")

# ---------------------------------------------------------------------------
# Stat betöltés
# ---------------------------------------------------------------------------
func apply_stats_from_dict(stats: Dictionary) -> void:
	## GameManager.player_data és/vagy CharacterResource alapján tölti fel a statokat.
	if stats.has(GameManager.KEY_HP):
		max_health = int(stats[GameManager.KEY_HP])
		health     = max_health
	if stats.has(GameManager.KEY_DMG):
		damage = int(stats[GameManager.KEY_DMG])
	if stats.has(GameManager.KEY_SPEED):
		move_speed = float(stats[GameManager.KEY_SPEED])

# ---------------------------------------------------------------------------
# Sebzés / gyógyítás
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	if not is_alive:
		return
	health = max(health - amount, 0)
	emit_signal("stats_changed", self)
	if health == 0:
		die()

func heal(amount: int) -> void:
	if not is_alive:
		return
	health = min(health + amount, max_health)
	emit_signal("stats_changed", self)

# ---------------------------------------------------------------------------
# Halál
# ---------------------------------------------------------------------------
## Alap halálkezelés.
## FONTOS: szándékosan NEM hív queue_free()-t – a leszármazottak maguk kezelik
## a saját cleanup-jukat (animáció lejátszás, LevelManager értesítés stb.):
##   BaseEnemy  → halál animáció + queue_free az _on_died()-ben
##   BasePlayer → player_died signal + LevelManager.on_player_death()
func die() -> void:
	if not is_alive:
		return
	is_alive = false
