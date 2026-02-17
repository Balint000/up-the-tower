extends Node
# Mock game manager for testing

signal state_changed(old_state, new_state)
signal score_changed(new_score)
signal level_changed(new_level)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var score: int = 0
var current_level: int = 1

func change_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func reset_score() -> void:
	score = 0
	score_changed.emit(score)

func next_level() -> void:
	current_level += 1
	level_changed.emit(current_level)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

func game_over() -> void:
	change_state(GameState.GAME_OVER)
