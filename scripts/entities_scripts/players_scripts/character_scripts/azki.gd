extends PlayerStats

const CHARACTER_NAME: String = "AZKi"
const CHARACTER_INDEX: int = 1
const DEFAULT_UNLOCKED: Array[int] = [139, 154, 170]

# Score: 4.265 + 5% Crit Rate
# Buffer - Skills

func set_base_stats() -> void: # TODO: change name
	# TODO: temporary code
	animation = load("res://entities/character_animations/azki.tres")
	if base:
		base.get_node(^"Animation").sprite_frames = animation
		base.get_node(^"Animation").play(&"down_idle")

	base_health = 373 # +173 (+0.865 T1)
	base_mana = 40 # +30 (+3 T1)
	base_stamina = 100
	base_defense = 8 # -2 (-0.2 T1)
	base_ward = 6 # -4 (-0.8 T1)
	base_strength = 9 # -1 (-0.2 T1)
	base_intelligence = 12 # +2 (+0.4 T1)
	base_speed = 2 # +2 (+2 T1)
	base_agility = 2 # +2 (+2 T1)
	base_crit_chance = 0.10 # +0.05 Crit Rate
	base_crit_damage = 0.50
