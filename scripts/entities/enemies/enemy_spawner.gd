## @class EnemySpawner
## @brief Spawns an enemy instance based on a CharacterResource entry from DataDb.
##
## The enemy type is identified by its character_id (enemy_id), which is used
## to fetch the corresponding CharacterResource from DataDb.enemies. The
## CharacterResource.scene_path points to the enemy scene (e.g. knightEnemy.tscn),
## which is then instantiated as a BaseEnemy and configured via set_character_resource().
class_name EnemySpawner
extends Node2D

## @var enemy_id
## @brief ID of the enemy to spawn, must match CharacterResource.character_id in DataDb.enemies.
@export var enemy_id: String = "enemy_knight"

## @var enemy_instance
## @brief Reference to the spawned enemy, if one was created.
var enemy_instance: BaseEnemy = null


## @brief Called when the spawner enters the scene tree. Defers actual spawn.
func _ready() -> void:
	call_deferred("_spawn_enemy")


## @brief Looks up the enemy resource in DataDb and spawns a configured BaseEnemy.
func _spawn_enemy() -> void:
	if DataDb == null:
		push_error("EnemySpawner: DataDb autoload is not available!")
		return

	# 1) Enemy CharacterResource from DataDb.enemies (via helper).
	var enemy_res: CharacterResource = DataDb.get_enemy(enemy_id)
	if enemy_res == null:
		push_error("EnemySpawner: EnemyResource not found: " + enemy_id)
		return

	# 2) Scene path from the resource (same pattern as PlayerSpawner).
	if enemy_res.scene_path.is_empty():
		push_error("EnemySpawner: scene_path is empty for enemy_id: " + enemy_id)
		return

	if not ResourceLoader.exists(enemy_res.scene_path):
		push_error("EnemySpawner: scene_path does not exist: " + enemy_res.scene_path)
		return

	var scene: PackedScene = load(enemy_res.scene_path)
	if scene == null:
		push_error("EnemySpawner: Failed to load scene: " + enemy_res.scene_path)
		return

	# 3) Instantiate and cast to BaseEnemy.
	enemy_instance = scene.instantiate() as BaseEnemy
	if enemy_instance == null:
		push_error("EnemySpawner: Instance is not a BaseEnemy (scene: " + enemy_res.scene_path + ")")
		return

	# 4) Position and add to current scene.
	enemy_instance.global_position = global_position
	get_tree().get_current_scene().add_child.call_deferred(enemy_instance)

	# 5) Apply stats from the CharacterResource via BaseEnemy API.
	enemy_instance.set_character_resource(enemy_res)
