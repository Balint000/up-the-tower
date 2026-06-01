## A collectible item placed in the game world.
##
## Listens for any [Entity] entering its [Area2D] and adds the corresponding
## item to the player's inventory via [method GameManager.inventory_add].
## The item type is identified by [member item_id], which must match a key
## in [DataDb]. After being picked up the node removes itself from the scene.
extends Area2D
class_name WorldItem

## Identifier of the item this pickup represents (e.g. [code]"basic_sword"[/code]).
## Must match a valid key in [DataDb].
@export var item_id: String = ""

## Optional sprite displaying the item's appearance in the world.
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
## Collision shape that defines the pickup area.
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

## Optionally loads visual data from the [ItemResource] (e.g. icon texture),
## then connects the body-entered signal to detect player contact.
func _ready() -> void:
	if item_id != "":
		var item_res = DataDb.get_item(item_id)
		if item_res and sprite:
			# Uncomment to apply the item's texture when ItemResource supports it:
			# sprite.texture = item_res.texture
			pass

	body_entered.connect(_on_body_entered)


## Called when any physics body enters the pickup area.
## Adds [member item_id] to the inventory via [GameManager] and removes this
## node. Skips non-Entity bodies and ignores pickups with an empty [member item_id].
## [param body] The [Node] that entered the area.
func _on_body_entered(body: Node) -> void:
	if not (body is Entity):
		return

	if item_id == "":
		return

	if GameManager != null:
		GameManager.inventory_add(item_id, 1)

	queue_free()
