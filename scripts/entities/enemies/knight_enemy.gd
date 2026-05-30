## Concrete [BaseEnemy] variant representing the knight enemy type.
##
## All [CharacterResource] handling (stats, scene path) is performed by
## [DataDb] and [EnemySpawner]. This script only exists as an anchor for
## future knight-specific behaviour or animation overrides.
extends BaseEnemy

## Forwards to [method BaseEnemy._ready].
## Add any knight-specific initialisation here as the game grows.
func _ready() -> void:
	super._ready()
	# Optional: additional knight-specific setup can go here.
