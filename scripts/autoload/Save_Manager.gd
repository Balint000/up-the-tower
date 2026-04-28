extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Save_Manager Init")

var save_path_json: String = "user://save_files/savegame.json"
var save_path_binary: String = "user://save_files/savegame.save"

## jatekos adat mentése
func save_player_data_json(runtime_data: Dictionary) -> void:
	runtime_data["timestamp"] = Time.get_unix_time_from_system()
	
	var err: Error = FileHandler.store_json_file(runtime_data, save_path_json, true)
	if err != OK:
		push_error("Nem lehet menteni (JSON): ", error_string(err))
	else:
		print("Save_manager mentése sikeres")
		# print("Valószínusithető Útvonal srácok, az ez (Bossnak linuxon más valszeg): C:/Users/(fiókod)/AppData/Roaming/Godot/app_userdata/up-the-tower/save_files")

func load_player_data_json() -> Dictionary:
	var save_data: Dictionary = {}
	var err: Error = FileHandler.open_json_file(save_path_json, save_data)
	if err != OK:
		push_error("Nemtudom betölteni a mentett adatokat (JSON): ", error_string(err))
		return {}
	
	err = verify_save_data_json(save_data)
	if err != OK:
		push_error("Nem jó mentett adat struktúra")
		return {}
	
	print("Mentett adatok sikeresen betöltve")
	
	return save_data

func verify_save_data_json(save_data: Dictionary) -> Error:

	var required_keys = [
		"level",
		"xp",
		"inventory",
		"selected_character",
		"statistics",
		"equipped_items"
	]

	for key in required_keys:
		if not save_data.has(key):
			push_error("Hiányzó kulcs a mentésben: " + key)
			return ERR_DOES_NOT_EXIST
	
	convert_int_keys(save_data, ["level", "xp"])
	convert_int_keys(save_data["statistics"], ["kills", "deaths"])

	return OK

func convert_int_keys(dict: Dictionary, keys: Array) -> void:
	for key in keys:
		if dict.has(key):
			dict[key] = int(dict[key])
