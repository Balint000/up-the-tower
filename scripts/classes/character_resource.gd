## character_resource.gd
## ==========================================================================
## CharacterResource – egy játszható karakter statikus adatai.
##
## Elhelyezés: scripts/classes/character_resource.gd
## Példányok:  data/characters/knight.tres
##             data/characters/mage.tres
##             data/characters/archer.tres
##             data/characters/thief.tres
##
## Használat:
##   var res: CharacterResource = load("res://data/characters/knight.tres")
##   print(res.character_name, res.max_health)
##
## A GameManager a selected_character string alapján betölti a megfelelő
## .tres fájlt, majd a PlayerSpawner átadja a karakternek.
## ==========================================================================

class_name CharacterResource
extends Resource

# ---------------------------------------------------------------------------
# Alap azonosítók
# ---------------------------------------------------------------------------

## Belső azonosító (GameManager.runtime_data["selected_character"] értékével
## meg kell egyeznie, pl. "knight", "mage", "archer", "thief").
@export var character_id: String = ""

## Megjelenített név (UI-on).
@export var character_name: String = ""

## Rövid leírás az inventory karakter-kártyán.
@export var description: String = ""

## Előnézeti kép az inventory képernyőn.
@export var portrait: Texture2D = null

# ---------------------------------------------------------------------------
# Alap stat-ok (nyers értékek, ItemResource bónuszok hozzáadódnak)
# ---------------------------------------------------------------------------

@export_group("Stats")
@export var base_hp: int   = 100
@export var base_dmg: int  = 20
## Mozgási sebesség (px/s).
@export var base_spd: float = 180.0
## Ugrás indulósebessége (negatív = felfelé).
@export var jump_velocity: float = -360.0

## Unlocks
@export var unlock_level: int = 1
@export var is_unlocked: bool = true

# ---------------------------------------------------------------------------
# Képesség (Shift gomb)
# ---------------------------------------------------------------------------

@export_group("Ability")

## Képesség típusa. A BasePlayer._handle_action_input() ezt olvassa és
## a megfelelő metódust hívja.
## Érvényes értékek: "dash", "double_jump", "block", "fireball"
@export_enum("dash", "double_jump", "block", "fireball") var ability_type: String = "dash"

## Képesség cooldown (másodperc).
@export var ability_cooldown: float = 1.2

## Képesség erőssége (jelentése ability_type-onként változó):
## dash       → impulzus px/s
## double_jump→ második ugrás velocity (negatív)
## block       → sebzés csökkentési arány 0-1
## fireball   → lövedék sebzése
@export var ability_power: float = 350.0

# ---------------------------------------------------------------------------
# Scene útvonal
# ---------------------------------------------------------------------------

@export_group("Scene")

## A karakter .tscn fájljának útvonala.
## A PlayerSpawner ezt az útvonalat tölti be dinamikusan.
## Például: "res://scenes/entities/player/MainCharacter.tscn"
@export_file("*.tscn") var scene_path: String = ""
