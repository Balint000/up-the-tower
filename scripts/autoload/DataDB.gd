extends Node

var characters: Dictionary = {}
var enemies: Dictionary = {}
var items: Dictionary = {}

@export var character_paths: Array[String] = [
	"res://data/characters/knight.tres",
	"res://data/characters/mage.tres",
	"res://data/characters/archer.tres",
	"res://data/characters/thief.tres", 
	# add others
]

@export var enemies_paths: Array[String] = [
	"res://data/enemies/enemy_knight.tres",
	"res://data/enemies/enemy_flying.tres",
	"res://data/enemies/enemy_archer.tres",
	"res://data/enemies/enemy_charger.tres",
	# add others
]

@export var item_paths: Array[String] = [
	"res://data/items/basic_sword.tres",
	"res://data/items/health_potion.tres",
	"res://data/items/bag.tres",
	"res://data/items/apple.tres",
	"res://data/items/beer.tres",
	"res://data/items/key.tres",
	"res://data/items/sword_common.tres",
	"res://data/items/sword_rare.tres",
	"res://data/items/sword_epic.tres",
	"res://data/items/basic_boot.tres",
	"res://data/items/boot_common.tres",
	"res://data/items/boot_rare.tres",
	"res://data/items/boot_epic.tres",
	"res://data/items/basic_helmet.tres",
	"res://data/items/helmet_common.tres",
	"res://data/items/helmet_rare.tres",
	"res://data/items/helmet_epic.tres"
]

func _ready() -> void:
	_load_characters()
	_load_items()
	_load_enemies()
	print("DataDB betöltve: %d items, %d characters, %d enemies" % [items.size(), characters.size(), enemies.size()])

func _load_characters() -> void:
	for path in character_paths:
		if ResourceLoader.exists(path):
			var res: CharacterResource = load(path)
			if res and res.character_id != "":
				characters[res.character_id] = res

func _load_enemies() -> void:
	for path in enemies_paths:
		if ResourceLoader.exists(path):
			var res: CharacterResource = load(path)
			if res and res.character_id != "":
				enemies[res.character_id] = res

func _load_items() -> void:
	for path in item_paths:
		if ResourceLoader.exists(path):
			var res: ItemResource = load(path)
			if res and res.id != "":
				items[res.id] = res

func get_character(id: String) -> CharacterResource:
	return characters.get(id)

func get_enemy(id: String) -> CharacterResource:
	return enemies.get(id)

func get_item(id: String) -> ItemResource:
	return items.get(id)

# =============================================================================
#  FILTERS
# =============================================================================
func get_items_by_slot(slot: ItemResource.ItemType) -> Array:
	var result = []
	for item_id in items:
		var item = items[item_id]
		if item.slot == slot:
			result.append(item_id)
	return result

func get_items_by_type(type: ItemResource.ItemType) -> Array:
	var result = []
	for item_id in items:
		var item = items[item_id]
		if item.type == type:
			result.append(item_id)
	return result

func get_items_by_rarity(rarity: String) -> Array:
	var result = []
	for item_id in items:
		var item = items[item_id]
		if item.rarity.to_lower() == rarity.to_lower():
			result.append(item_id)
	return result
