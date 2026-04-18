extends Node

var characters: Dictionary = {}
var items: Dictionary = {}

@export var character_paths: Array[String] = [
	"res://data/characters/knight.tres",
	# add others
]

@export var item_paths: Array[String] = [
	"res://data/items/basic_sword.tres",
	"res://data/items/health_potion.tres",
	# ...
]

func _ready() -> void:
	_load_characters()
	_load_items()

func _load_characters() -> void:
	for path in character_paths:
		if ResourceLoader.exists(path):
			var res: CharacterResource = load(path)
			if res and res.character_id != "":
				characters[res.character_id] = res

func _load_items() -> void:
	for path in item_paths:
		if ResourceLoader.exists(path):
			var res: ItemResource = load(path)
			if res and res.item_id != "":
				items[res.item_id] = res

func get_character(id: String) -> CharacterResource:
	return characters.get(id)

func get_item(id: String) -> ItemResource:
	return items.get(id)
