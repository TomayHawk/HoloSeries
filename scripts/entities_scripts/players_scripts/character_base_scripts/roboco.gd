extends CharacterBase

const CHARACTER_NAME: String = "Roboco"
const CHARACTER_INDEX: int = 2

# Score: 4.025 + 20 Stamina + 15% Crit Damage
# Physical - Tank

func set_base_stats(stats: PlayerStats) -> void:
	stats.base_health = 465 # +265 (+1.325 T1)
	stats.base_mana = 10
	stats.base_stamina = 120 # +20 Stamina
	stats.base_defense = 18 # +8 (+1.6 T1)
	stats.base_ward = 13 # +3 (+0.6 T1)
	stats.base_strength = 16 # +6 (+1.2 T1)
	stats.base_intelligence = 4 # -6 (-1.2 T1)
	stats.base_speed = 0
	stats.base_agility = 1 # +1 (+1.0 T1)
	stats.base_crit_chance = 0.05
	stats.base_crit_damage = 0.65 # +0.15 Crit Damage
