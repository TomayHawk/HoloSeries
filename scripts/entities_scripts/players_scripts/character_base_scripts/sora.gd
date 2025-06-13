extends CharacterBase

const CHARACTER_NAME: String = "Tokino Sora"
const CHARACTER_INDEX: int = 0

# Score: 4.55
# Buffer - Healer

func set_base_stats(stats: PlayerStats) -> void:
	stats.base_health = 99999 # +190 (+0.95 T1)
	stats.base_mana = 9999 # +18 (+1.8 T1)
	stats.base_stamina = 500
	stats.base_defense = 1000
	stats.base_ward = 1000
	stats.base_strength = 1000
	stats.base_intelligence = 1000 # +4 (+0.8 T1)
	stats.base_speed = 1 # +1 (+1 T1)
	stats.base_agility = 256 # +1 (+1 T1)
	stats.base_crit_chance = 0.50
	stats.base_crit_damage = 0.50
