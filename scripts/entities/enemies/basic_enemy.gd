extends Entity
## Alap ellenség, aki az Entity-t használja közös statokra.

func _ready() -> void:
	super._ready()
	faction = "enemy"
	entity_name = "basic_enemy"
	## Ha DataDb-ben is van enemy karakter resource, itt töltheted be:
	## var enemy_res = DataDb.get_character("enemy_knight")
	## apply_stats_from_dict({
	##     GameManager.KEY_HP: enemy_res.base_hp,
	##     GameManager.KEY_DMG: enemy_res.base_dmg,
	##     GameManager.KEY_SPEED: enemy_res.base_spd,
	## })

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	## Itt jön az AI mozgás / támadás logika.
	pass
