extends BasePlayer
## PlayerKnight – játszható lovag karakter.
##
## Csak a lovag-specifikus dolgokat tartalmazza; minden közös logika
## (sebzés, halál, flash, LevelManager hívás, resource betöltés stb.)
## a BasePlayer-ben van.
##
## Amit itt override-olunk:
##   • _get_animation_name() – a Soldier sprite sheet "walk"-ot használ "run" helyett,
##                             JUMP és FALL állnapotban nincs külön frame, "idle" játszik
##   • _use_selected_item()  – inventory-val rendelkező lovag specifikus item használat

@onready var _camera:    Camera2D = $Camera2D  if has_node("Camera2D")  else null
@onready var _inventory: Node     = $Inventory if has_node("Inventory") else null

# ---------------------------------------------------------------------------
# Animáció – Soldier sprite sheet naming
# ---------------------------------------------------------------------------
func _get_animation_name() -> StringName:
	match _state:
		State.IDLE:   return &"idle"
		State.RUN:    return &"walk"    # Soldier atlas: "walk", nem "run"
		State.JUMP:   return &"idle"    # nincs külön jump frame
		State.FALL:   return &"idle"    # nincs külön fall frame
		State.ATTACK: return &"attack"
		State.HURT:   return &"hurt"
		State.DEAD:   return &"death"
	return &"idle"

# ---------------------------------------------------------------------------
# Item használat – inventory-val rendelkező lovag
# ---------------------------------------------------------------------------
func _use_selected_item() -> void:
	if _inventory != null and _inventory.has_method("use_selected"):
		_inventory.use_selected(self)
		emit_signal("stats_changed", self)
