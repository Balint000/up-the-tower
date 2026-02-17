extends GutTest
# Tests for game manager singleton

var game_manager

func before_each():
	# Create a mock game manager
	game_manager = Node.new()
	game_manager.name = "GameManager"
	game_manager.set_script(load("res://tests/unit/mocks/mock_game_manager.gd"))
	add_child_autofree(game_manager)

func test_game_manager_exists():
	assert_not_null(game_manager, "GameManager should exist")

func test_game_starts_in_menu_state():
	assert_eq(game_manager.current_state, game_manager.GameState.MENU,
		"Game should start in MENU state")

func test_game_can_transition_to_playing():
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING,
		"Game should transition to PLAYING state")

func test_game_tracks_score():
	assert_eq(game_manager.score, 0, "Score should start at zero")
	
	game_manager.add_score(100)
	
	assert_eq(game_manager.score, 100, "Score should increase")

func test_game_tracks_level():
	assert_eq(game_manager.current_level, 1, 
		"Game should start at level 1")

func test_game_can_pause():
	game_manager.change_state(game_manager.GameState.PLAYING)
	game_manager.pause_game()
	
	assert_eq(game_manager.current_state, game_manager.GameState.PAUSED,
		"Game should be paused")

func test_game_can_resume():
	game_manager.change_state(game_manager.GameState.PAUSED)
	game_manager.resume_game()
	
	assert_eq(game_manager.current_state, game_manager.GameState.PLAYING,
		"Game should resume to playing")

func test_game_emits_signal_on_state_change():
	watch_signals(game_manager)
	
	game_manager.change_state(game_manager.GameState.PLAYING)
	
	assert_signal_emitted(game_manager, "state_changed",
		"Should emit state_changed signal")
