extends PlayerStats

const CHARACTER_NAME: String = "Himemori Luna"
const CHARACTER_INDEX: int = 4
const DEFAULT_UNLOCKED: Array[int] = [100, 132, 147]

# Score: 4.285
# Healer

func set_base_stats() -> void: # TODO: change name
	# TODO: temporary code
	animation = load("res://entities/character_animations/luna.tres")
	if base:
		base.get_node(^"Animation").sprite_frames = animation
		base.get_node(^"Animation").play(&"down_idle")

	base_health = 377 # +177 (+0.885 T1)
	base_mana = 36 # +26 (+2.6 T1)
	base_stamina = 100
	base_defense = 3 # -7 (-1.6 T1)
	base_ward = 13 # +3 (+0.6 T1)
	base_strength = 4 # -6 (-0.8 T1)
	base_intelligence = 18 # +8 (+1.6 T1)
	base_speed = 1 # +1 (+1 T1)
	base_agility = 1 # +1 (+1 T1)
	base_crit_chance = 0.05
	base_crit_damage = 0.50
