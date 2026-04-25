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

extends Resource
class_name ItemResource

## Equipment Slots
enum EquipSlot {
	NONE,
	HELMET,
	WEAPON,
	BOOTS
}

## Item Types
enum ItemType {
	EQUIPPABLE,
	CONSUMABLE,
	KEY_ITEM,
	BAG
}

## Basic Info
@export var id: String = ""
@export var name: String = "Unnamed Item"
@export var short_name: String = ""
@export var description: String = ""
@export var icon: Texture2D

## Type & Slot
@export var type: ItemType = ItemType.CONSUMABLE
@export var slot: EquipSlot = EquipSlot.NONE

## Rarity
@export var rarity: String = "common"  # common, rare, mythic

## Stats (for equipment)
@export var hp: int = 0
@export var dmg: int = 0
@export var spd: int = 0

## Bag loot pool (for bag type items)
@export var pool: Array[String] = []

## Consumable effect
@export var effect_hp: int = 0
@export var effect_spd: int = 0
@export var effect_duration: float = 0.0
