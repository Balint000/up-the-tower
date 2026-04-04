extends GutTest

const SAVE_MANAGER_PATH := "res://scripts/autoload/Save_Manager.gd"

func _create_save_manager() -> Node:
	var script := load(SAVE_MANAGER_PATH)
	return script.new()

func test_verify_save_data_json_ok_when_all_keys_present():
	var sm: Node = _create_save_manager()

	var save_data: Dictionary = {
		"level": 2,
		"xp": 100,
		"inventory": ["basic_sword"],
		"selected_character": "knight",
		"statistics": {
			"kills": 10,
			"deaths": 2,
		},
		"equipped_items": {
			"weapon": "basic_sword",
			"armor": "none",
		}
	}

	var err: Error = sm.verify_save_data_json(save_data)
	assert_eq(err, OK, "verify_save_data_json should return OK for valid data")

	# Integer fields should be converted to int
	assert_true(typeof(save_data["level"]) == TYPE_INT, "Level should be int")
	assert_true(typeof(save_data["xp"]) == TYPE_INT, "XP should be int")
	assert_true(typeof(save_data["statistics"]["kills"]) == TYPE_INT, "Kills should be int")
	assert_true(typeof(save_data["statistics"]["deaths"]) == TYPE_INT, "Deaths should be int")
