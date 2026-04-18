## item_resource.gd
## ==========================================================================
## ItemResource – egy tárgy (fegyver, páncél, egyszer használatos) adatai.
##
## Elhelyezés: scripts/classes/item_resource.gd
## Példányok:  data/items/basic_sword.tres
##             data/items/iron_shield.tres
##             data/items/health_potion.tres
##
## A tárgyakat a GameManager.runtime_data["inventory"] tömb azonosítókkal
## (item_id string) tárolja; az inventory UI betölti a .tres-t az ID alapján.
## ==========================================================================

class_name ItemResource
extends Resource

# ---------------------------------------------------------------------------
# Azonosítók és megjelenítés
# ---------------------------------------------------------------------------

## Egyedi azonosító (runtime_data["inventory"] és ["equipped_items"] ezzel hivatkozik).
@export var item_id: String = ""

## Megjelenített név.
@export var item_name: String = ""

## Rövid leírás (inventory tooltip).
@export var description: String = ""

## Inventory ikon.
@export var icon: Texture2D = null

# ---------------------------------------------------------------------------
# Tárgy típusa
# ---------------------------------------------------------------------------

## "weapon"      – fegyver (weapon slotba kerül, damage bónuszt ad)
## "armor"       – páncél (armor slotba kerül, health bónuszt ad)
## "consumable"  – egyszer használatos (használatkor elfogy)
## "accessory"   – kiegészítő (passzív stat bónusz, nincs külön slot)
@export_enum("weapon", "helmet", "consumable", "accessory") var item_type: String = "weapon"

# ---------------------------------------------------------------------------
# Stat bónuszok (additív; a BasePlayer._apply_stats()-ban összeadódnak)
# ---------------------------------------------------------------------------

@export_group("Stat buffs")

## Hozzáadott sebzés (nyers szám, nem szorzó).
@export var damage_bonus: int   = 0

## Hozzáadott életerő (nyers szám).
@export var health_bonus: int   = 0

## Sebesség bónusz (px/s; negatív értéke is lehetséges, pl. nehéz páncél).
@export var speed_bonus: float  = 0.0

# ---------------------------------------------------------------------------
# Fegyver-specifikus adatok
# ---------------------------------------------------------------------------

@export_group("Weapon")

## Fegyver hatótávolság (px). 0 = az alap érték érvényes.
@export var attack_range: float = 0.0

## Fegyver attack cooldown felülírása (s). 0 = alapértelmezett.
@export var attack_cooldown_override: float = 0.0

@export_group("Helmet")

## Fegyver hatótávolság (px). 0 = az alap érték érvényes.
@export var attack_range: float = 0.0

## Fegyver attack cooldown felülírása (s). 0 = alapértelmezett.
@export var attack_cooldown_override: float = 0.0

# ---------------------------------------------------------------------------
# Fogyasztható tárgy adatai
# ---------------------------------------------------------------------------

@export_group("Consumable")

## "heal"        – életerőt tölt vissza
## "damage_buff" – ideiglenes sebzésnövelés
## "speed_buff"  – ideiglenes sebességnövelés
@export_enum("heal", "damage_buff", "speed_buff") var consumable_effect: String = "heal"

## Az effekt erőssége (gyógyításnál HP, buff-nál szorzó pl. 1.5).
@export var effect_value: float = 30.0

## Buff időtartama másodpercben (0 = azonnali effekt).
@export var effect_duration: float = 0.0

# ---------------------------------------------------------------------------
# Segédmetódusok
# ---------------------------------------------------------------------------

## True ha a tárgy felszerelhető (weapon vagy armor slot-ba kerülhet).
func is_equippable() -> bool:
	return item_type in ["weapon", "armor"]


## True ha a tárgy egyszer használatos.
func is_consumable() -> bool:
	return item_type == "consumable"
