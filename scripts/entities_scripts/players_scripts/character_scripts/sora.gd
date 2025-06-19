extends PlayerStats

const CHARACTER_NAME: String = "Tokino Sora"
const CHARACTER_INDEX: int = 0
const DEFAULT_UNLOCKED: Array[int] = [135, 167, 182]

# Score: 4.55
# Buffer - Healer

func set_base_stats() -> void: # TODO: change name
	# TODO: temporary code
	animation = load("res://entities/players/character_animations/sora.tres")
	if base:
		base.get_node(^"Animation").sprite_frames = animation
		base.get_node(^"Animation").play(&"down_idle")

	base_health = 99999 # +190 (+0.95 T1)
	base_mana = 9999 # +18 (+1.8 T1)
	base_stamina = 500
	base_defense = 1000
	base_ward = 1000
	base_strength = 1000
	base_intelligence = 1000 # +4 (+0.8 T1)
	base_speed = 1 # +1 (+1 T1)
	base_agility = 256 # +1 (+1 T1)
	base_crit_chance = 0.50
	base_crit_damage = 0.50
