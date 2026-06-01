## Spawns the selected player character into the active level.
##
## Reads [constant GameManager.KEY_SELECTED_CHARACTER] from runtime data,
## fetches the matching [CharacterResource] via [DataDb.get_character],
## loads the scene at [member CharacterResource.scene_path], and adds the
## resulting [BasePlayer] instance at this node's world position.
## Notifies [LevelManager] of the spawned player after creation.
extends CharacterBody2D

## Reference to the spawned player instance, or [code]null[/code] before spawning.
var player_instance: BasePlayer = null

## Defers the spawn to the next frame to ensure all autoloads are ready.
func _ready() -> void:
	call_deferred("_spawn_player")


## Full spawn sequence with error checking at every step:
## 1. Validates [GameManager] and [DataDb] autoloads.
## 2. Reads the selected character ID from runtime data.
## 3. Fetches the [CharacterResource] from [DataDb].
## 4. Validates and loads the scene at [member CharacterResource.scene_path].
## 5. Instantiates and positions the player at this spawner's location.
## 6. Notifies [LevelManager.set_player] with the new instance.
func _spawn_player() -> void:
	if GameManager == null:
		push_error("PlayerSpawner: GameManager autoload is not available!")
		return
	if DataDb == null:
		push_error("PlayerSpawner: DataDb autoload is not available!")
		return

	var selected_char_id: String = GameManager.runtime_data.get(GameManager.KEY_SELECTED_CHARACTER, "knight")

	var char_res: CharacterResource = DataDb.get_character(selected_char_id)
	if char_res == null:
		push_error("PlayerSpawner: CharacterResource not found: " + selected_char_id)
		return

	if char_res.scene_path.is_empty():
		push_error("PlayerSpawner: scene_path is empty for character: " + selected_char_id)
		return

	if not ResourceLoader.exists(char_res.scene_path):
		push_error("PlayerSpawner: scene_path does not exist: " + char_res.scene_path)
		return

	var scene: PackedScene = load(char_res.scene_path)
	if scene == null:
		push_error("PlayerSpawner: Failed to load scene: " + char_res.scene_path)
		return

	player_instance = scene.instantiate() as BasePlayer
	if player_instance == null:
		push_error("PlayerSpawner: Instance is not a BasePlayer (scene: " + char_res.scene_path + ")")
		return

	player_instance.global_position = global_position
	get_tree().get_current_scene().add_child.call_deferred(player_instance)

	if LevelManager.has_method("set_player"):
		LevelManager.set_player(player_instance)
