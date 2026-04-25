extends Area2D
class_name WorldItem
## Világban lévő felvehető tárgy.
## - DataDb-ből származó item_id alapján tudja, mit kell adni.
## - GameManager.inventory_add()-ot hív, így integrálódik a meglévő inventory rendszerrel.

@export var item_id: String = ""  ## pl. "basic_sword", "health_potion"

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready() -> void:
	## Beállíthatod a sprite-ot az ItemResource alapján, ha akarod.
	if item_id != "":
		var item_res = DataDb.get_item(item_id)
		if item_res and sprite:
			## Ha az ItemResource-nak van ikon/textúra mezője, itt setelheted.
			## sprite.texture = item_res.texture
			pass

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	## Csak akkor reagálunk, ha player (vagy általános Entity) lép bele.
	if not (body is Entity):
		return

	if item_id == "":
		return

	## Inventory frissítés a GameManageren keresztül.
	if GameManager != null:
		GameManager.inventory_add(item_id, 1)

	## Ha a tárgy kulcs, potion stb., a GameManager + Inventory rendszer már tudja kezelni.
	queue_free()
