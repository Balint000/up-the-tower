## player_spawner.gd
## ==========================================================================
## PlayerSpawner – dinamikusan példányosítja a kiválasztott karaktert.
##
## Elhelyezés: scripts/entities/player/player_spawner.gd
## Scene:      Minden Level .tscn-ben legyen egy Node2D erre a scriptre,
##             a kívánt spawn pozícióban.
##
## Munkafolyamat:
##   1. A játékos az inventory-ban kiválaszt egy karaktert → GameManager menti.
##   2. LevelManager betölti a pálya scene-t.
##   3. Ez a node _ready()-ben:
##        a) lekéri a selected_character ID-t a GameManager-ből
##        b) betölti a megfelelő CharacterResource .tres fájlt
##        c) példányosítja a karakter .tscn-t
##        d) átadja a CharacterResource-t a BasePlayer-nek
##        e) hozzáadja a scene-hez ezen a node pozícióján
##
## Szükséges projekt konfiguráció:
##   data/characters/ mappában legyenek a .tres fájlok, az item_id mezőkkel
##   (pl. "knight", "mage", "archer", "thief").
## ==========================================================================

extends Node2D

## Tartalék karakter ha a kiválasztott nem található.
const FALLBACK_CHARACTER_ID: String = "knight"

## Karakterek .tres erőforrásainak helye.
## A betöltési út: CHARACTER_DATA_PATH + character_id + ".tres"
const CHARACTER_DATA_PATH: String = "res://data/characters/"

func _ready() -> void:
	_spawn_player()


## Fő spawning logika.
func _spawn_player() -> void:
	# 1. Karakter ID lekérdezése
	var character_id: String = GameManager.runtime_data.get(
		GameManager.KEY_SELECTED_CHARACTER,
		FALLBACK_CHARACTER_ID
	)

	# 2. CharacterResource betöltése
	var resource_path: String = CHARACTER_DATA_PATH + character_id + ".tres"
	var char_res: CharacterResource = _load_character_resource(resource_path, character_id)
	if char_res == null:
		push_error("PlayerSpawner: CharacterResource nem található: " + resource_path)
		return

	# 3. Karakter .tscn betöltése
	if char_res.scene_path.is_empty():
		push_error("PlayerSpawner: scene_path üres a(z) '%s' karakternél" % character_id)
		return

	var packed: PackedScene = load(char_res.scene_path)
	if packed == null:
		push_error("PlayerSpawner: nem sikerült betölteni: " + char_res.scene_path)
		return

	# 4. Példányosítás és pozicionálás
	var player: Node = packed.instantiate()
	player.global_position = global_position

	# 5. CharacterResource átadása – a BasePlayer ezt _ready()-ben veszi át
	if player.has_method("setup"):
		player.setup(char_res, _collect_equipped_items())
	else:
		push_warning("PlayerSpawner: a karakter scriptnek nincs setup() metódusa")

	# 6. Hozzáadás a szülő scene-hez (nem erre a Node2D-re, hanem mellé)
	get_parent().add_child(player)

	# 7. Camera2D bekötése
	_attach_camera(player)

	# 8. Saját node törlése (nincs több dolgunk)
	queue_free()


## CharacterResource betöltése; fallback-kel ha az ID nem található.
func _load_character_resource(path: String, character_id: String) -> CharacterResource:
	if not ResourceLoader.exists(path):
		push_warning("PlayerSpawner: '%s' nem létezik, fallback: %s" % [path, FALLBACK_CHARACTER_ID])
		var fallback_path := CHARACTER_DATA_PATH + FALLBACK_CHARACTER_ID + ".tres"
		if ResourceLoader.exists(fallback_path):
			return load(fallback_path) as CharacterResource
		return null
	return load(path) as CharacterResource


## Felszerelt tárgyak ItemResource listájának összeállítása.
## A GameManager "equipped_items" szótárából (weapon, armor slot).
func _collect_equipped_items() -> Array[ItemResource]:
	var result: Array[ItemResource] = []
	var equipped: Dictionary = GameManager.runtime_data.get(
		GameManager.KEY_EQUIPPED_ITEMS,
		{}
	)
	for slot_value in equipped.values():
		if slot_value is String and not slot_value.is_empty():
			var item_path = "res://data/items/" + slot_value + ".tres"
			if ResourceLoader.exists(item_path):
				var item := load(item_path) as ItemResource
				if item:
					result.append(item)
	return result


## Ha van Camera2D a pályán, kösse be a spawn-olt játékosra.
func _attach_camera(player: Node) -> void:
	var camera := _find_camera2d(get_parent())
	if camera and camera.has_method("set_target"):
		camera.set_target(player)
	elif camera:
		# Godot 4 Camera2D: reparent a játékosra
		var cam_parent: Node = camera.get_parent()
		cam_parent.remove_child(camera)
		player.add_child(camera)


## Rekurzív Camera2D keresés.
func _find_camera2d(node: Node) -> Camera2D:
	if node is Camera2D:
		return node
	for child in node.get_children():
		var found := _find_camera2d(child)
		if found:
			return found
	return null
