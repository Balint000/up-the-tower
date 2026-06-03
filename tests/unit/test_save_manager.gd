## @file test_save_manager.gd
## @brief Unit tests for [SaveManager] JSON save-data validation.
##
## SaveManager is an autoload singleton. The script is instantiated via
## load+new() to keep tests isolated from the running singleton.
##
## Covered: verify_save_data_json with valid data,
## missing individual keys, and integer type conversion.
extends GutTest


## @brief Filesystem path to the [SaveManager] GDScript.
const SAVE_MANAGER_PATH := "res://scripts/autoload/Save_Manager.gd"

## @brief Creates an isolated [SaveManager] instance.
## @return A new [SaveManager] node added to the scene tree.
func _create_save_manager() -> Node:
	var sm: Node = load(SAVE_MANAGER_PATH).new()
	add_child_autofree(sm)
	return sm


## @brief Builds a complete, valid save-data dictionary.
## @return A dictionary that verify_save_data_json should accept.
func _valid_save_data() -> Dictionary:
	return {
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
		},
		"unlocked_levels": [0, 1],
	}


## @brief verify_save_data_json must return OK when all required keys are present.
func test_verify_save_data_json_ok_when_all_keys_present() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()

	var err: Error = sm.verify_save_data_json(save_data)
	assert_eq(err, OK, "verify_save_data_json should return OK for valid data")


## @brief After verify_save_data_json, integer fields must have TYPE_INT
## regardless of whether they arrived as floats (as JSON parsing produces).
func test_verify_save_data_converts_int_fields() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()

	# Simulate JSON parsing where numbers arrive as floats.
	save_data["level"] = 2.0
	save_data["xp"] = 100.0
	save_data["statistics"]["kills"] = 10.0
	save_data["statistics"]["deaths"] = 2.0

	var _err = sm.verify_save_data_json(save_data)

	assert_eq(typeof(save_data["level"]), TYPE_INT, "'level' should be int")
	assert_eq(typeof(save_data["xp"]), TYPE_INT, "'xp' should be int")
	assert_eq(typeof(save_data["statistics"]["kills"]), TYPE_INT,  "'kills' should be int")
	assert_eq(typeof(save_data["statistics"]["deaths"]), TYPE_INT, "'deaths' should be int")

# Missing key validation

## @brief A save-data dictionary without "level" must be rejected.
func test_verify_returns_error_when_level_missing() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()
	save_data.erase("level")
	assert_ne(sm.verify_save_data_json(save_data), OK,
		"verify_save_data_json should fail when 'level' is missing")

## @brief A save-data dictionary without "xp" must be rejected.
func test_verify_returns_error_when_xp_missing() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()
	save_data.erase("xp")
	assert_ne(sm.verify_save_data_json(save_data), OK,
		"verify_save_data_json should fail when 'xp' is missing")

## @brief A save-data dictionary without "unlocked_levels" must be rejected.
## This key was ABSENT from the original test, causing it to always fail at runtime.
func test_verify_returns_error_when_unlocked_levels_missing() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()
	save_data.erase("unlocked_levels")
	assert_ne(sm.verify_save_data_json(save_data), OK,
		"verify_save_data_json should fail when 'unlocked_levels' is missing")

## @brief A save-data dictionary without "statistics" must be rejected.
func test_verify_returns_error_when_statistics_missing() -> void:
	var sm: Node = _create_save_manager()
	var save_data: Dictionary = _valid_save_data()
	save_data.erase("statistics")
	assert_ne(sm.verify_save_data_json(save_data), OK,
		"verify_save_data_json should fail when 'statistics' is missing")

## @brief An entirely empty dictionary must be rejected.
func test_verify_returns_error_for_empty_dict() -> void:
	var sm: Node = _create_save_manager()
	assert_ne(sm.verify_save_data_json({}), OK,
		"verify_save_data_json should fail for an empty dictionary")
