extends HBoxContainer

@onready var _hp = $Stat_HP/HpValue
@onready var _dmg = $Stat_Damage/DmgValue
@onready var _spd = $Stat_Speed/SpdValue

func set_stats(stats: Dictionary) -> void:
	_hp.text = str(stats.hp)
	_dmg.text = str(stats.dmg)
	_spd.text = str(stats.spd)
