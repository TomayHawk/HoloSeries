extends CharacterBase

const CHARACTER_NAME: String = "Himemori Luna"
const CHARACTER_INDEX: int = 4

# Score: 4.285
# Healer

func set_base_stats(stats: PlayerStats) -> void:
	stats.base_health = 377 # +177 (+0.885 T1)
	stats.base_mana = 36 # +26 (+2.6 T1)
	stats.base_stamina = 100
	stats.base_defense = 3 # -7 (-1.6 T1)
	stats.base_ward = 13 # +3 (+0.6 T1)
	stats.base_strength = 4 # -6 (-0.8 T1)
	stats.base_intelligence = 18 # +8 (+1.6 T1)
	stats.base_speed = 1 # +1 (+1 T1)
	stats.base_agility = 1 # +1 (+1 T1)
	stats.base_crit_chance = 0.05
	stats.base_crit_damage = 0.50
