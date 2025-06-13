extends CharacterBase

const CHARACTER_NAME: String = "AZKi"
const CHARACTER_INDEX: int = 1

# Score: 4.265 + 5% Crit Rate
# Buffer - Skills

func set_base_stats(stats: PlayerStats) -> void:
	stats.base_health = 373 # +173 (+0.865 T1)
	stats.base_mana = 40 # +30 (+3 T1)
	stats.base_stamina = 100
	stats.base_defense = 8 # -2 (-0.2 T1)
	stats.base_ward = 6 # -4 (-0.8 T1)
	stats.base_strength = 9 # -1 (-0.2 T1)
	stats.base_intelligence = 12 # +2 (+0.4 T1)
	stats.base_speed = 2 # +2 (+2 T1)
	stats.base_agility = 2 # +2 (+2 T1)
	stats.base_crit_chance = 0.10 # +0.05 Crit Rate
	stats.base_crit_damage = 0.50
