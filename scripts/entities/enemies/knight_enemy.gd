## @class KnightEnemy
## @brief Concrete variant of BaseEnemy for the knight enemy.
##
## This script does NOT load any resources on its own. All CharacterResource
## handling is done by DataDb + EnemySpawner. KnightEnemy only customizes
## behaviour/animations if needed.
extends BaseEnemy

## @brief Called when the knight enemy enters the scene tree.
## Currently just forwards to BaseEnemy._ready().
func _ready() -> void:
	super._ready()
	# Optional: additional per-knight setup can go here later
