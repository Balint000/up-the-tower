## Spawns an enemy instance from a [CharacterResource] entry in [DataDb].
##
## The enemy type is identified by [member enemy_id] which must match a
## [member CharacterResource.character_id] in [member DataDb.enemies].
## [member CharacterResource.scene_path] then points to the enemy scene
## (e.g. [code]knightEnemy.tscn[/code]) which is instantiated as a [BaseEnemy]
## and configured via [method BaseEnemy.set_character_resource].
class_name EnemySpawner
extends Node2D

## Identifier of the enemy to spawn.
## Must match [member CharacterResource.character_id] in [DataDb].
@export var enemy_id: String = "enemy_knight"

## Reference to the spawned enemy node, or [code]null[/code] if not yet spawned.
var enemy_instance: BaseEnemy = null


## Defers the actual spawn to the next frame so that all autoloads are ready.
func _ready() -> void:
	call_deferred("_spawn_enemy")


## Resolves the [CharacterResource] from [DataDb], loads the scene at
## [member CharacterResource.scene_path], instantiates it, positions it at
## this spawner's [member Node2D.global_position], applies stats, and adds it
## to the active scene. Emits detailed error messages for every failure case.
func _spawn_enemy() -> void:
	if DataDb == null:
		push_error("EnemySpawner: DataDb autoload is not available!")
		return

	# 1) Look up the enemy's CharacterResource by ID.
	var enemy_res: CharacterResource = DataDb.get_enemy(enemy_id)
	if enemy_res == null:
		push_error("EnemySpawner: EnemyResource not found for id: " + enemy_id)
		return

	# 2) Validate the scene path stored in the resource.
	if enemy_res.scene_path.is_empty():
		push_error("EnemySpawner: scene_path is empty for enemy_id: " + enemy_id)
		return

	if not ResourceLoader.exists(enemy_res.scene_path):
		push_error("EnemySpawner: scene_path does not exist: " + enemy_res.scene_path)
		return

	# 3) Load and instantiate the enemy scene.
	var scene: PackedScene = load(enemy_res.scene_path)
	if scene == null:
		push_error("EnemySpawner: Failed to load scene: " + enemy_res.scene_path)
		return

	enemy_instance = scene.instantiate() as BaseEnemy
	if enemy_instance == null:
		push_error("EnemySpawner: Instance is not a BaseEnemy (scene: " + enemy_res.scene_path + ")")
		return

	# 4) Position the enemy at the spawner's world position and add to the scene.
	enemy_instance.global_position = global_position
	get_tree().get_current_scene().add_child.call_deferred(enemy_instance)

	# 5) Apply stats from the CharacterResource via the BaseEnemy API.
	enemy_instance.set_character_resource(enemy_res)
