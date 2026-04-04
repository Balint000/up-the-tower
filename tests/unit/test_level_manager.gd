extends GutTest

func _create_level_manager() -> Level_Manager:
	return Level_Manager.new()

func test_level_zero_is_unlocked_by_default():
	var lm := _create_level_manager()

	assert_true(lm.is_unlocked(0), "Level 0 should be unlocked by default")
	assert_false(lm.has_save_data(), "Initially there should be no extra unlocked levels")

func test_unlock_level_adds_to_unlocked_list():
	var lm := _create_level_manager()

	lm.unlock_level(1)
	assert_true(lm.is_unlocked(1), "Level 1 should be unlocked after calling unlock_level(1)")
	assert_true(lm.has_save_data(), "has_save_data should be true when any level > 0 is unlocked")

func test_restore_unlocked_levels_always_keeps_level_zero():
	var lm := _create_level_manager()

	# Intentionally restore without 0 to test safety logic
	lm.restore_unlocked_levels([2, 3])

	assert_true(lm.is_unlocked(0), "restore_unlocked_levels must always keep level 0 unlocked")
	assert_true(lm.is_unlocked(2), "Level 2 should be unlocked after restore")
	assert_true(lm.is_unlocked(3), "Level 3 should be unlocked after restore")
