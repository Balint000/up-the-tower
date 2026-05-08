extends CharacterBody2D
## Player spawner: létrehozza az inventory-ban kiválasztott karakter példányát a pályán.
## A karakter scene_path-ját a CharacterResource.scene_path adja (DataDb + GameManager alapján).

var player_instance: BasePlayer = null

func _ready() -> void:
	call_deferred("_spawn_player")


func _spawn_player() -> void:
	## 1) GameManager + DataDb ellenőrzés
	if GameManager == null:
		push_error("PlayerSpawner: GameManager autoload nem elérhető!")
		return
	if DataDb == null:
		push_error("PlayerSpawner: DataDb autoload nem elérhető!")
		return

	## 2) Kiválasztott karakter ID lekérése a runtime_data-ból
	var selected_char_id: String = GameManager.runtime_data.get(GameManager.KEY_SELECTED_CHARACTER, "knight")

	## 3) CharacterResource lekérése
	var char_res: CharacterResource = DataDb.get_character(selected_char_id)
	if char_res == null:
		push_error("PlayerSpawner: CharacterResource nem található: " + selected_char_id)
		return

	## 4) Scene betöltése a CharacterResource.scene_path alapján
	if char_res.scene_path.is_empty():
		push_error("PlayerSpawner: scene_path üres a CharacterResource-ban: " + selected_char_id)
		return

	if not ResourceLoader.exists(char_res.scene_path):
		push_error("PlayerSpawner: scene_path nem létezik: " + char_res.scene_path)
		return

	var scene: PackedScene = load(char_res.scene_path)
	if scene == null:
		push_error("PlayerSpawner: nem sikerült betölteni a scene-t: " + char_res.scene_path)
		return

	## 5) Példányosítás
	player_instance = scene.instantiate() as BasePlayer
	if player_instance == null:
		push_error("PlayerSpawner: a példány nem BaseCharacter (scene: " + char_res.scene_path + ")")
		return

	## 6) Pozíció beállítása és hozzáadás a jelenethez
	player_instance.global_position = global_position
	get_tree().get_current_scene().add_child.call_deferred(player_instance)

	## 7) Opcionális: player referencia tárolása a GameManagerben
	if GameManager.has_method("set_player"):
		GameManager.set_player(player_instance)
