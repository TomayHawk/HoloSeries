extends PlayerStats

const CHARACTER_NAME: String = "Aki Rosenthal"
const CHARACTER_INDEX: int = 3
const DEFAULT_UNLOCKED: Array[int] = [491, 522, 523]

# Score: 4.18 + 2% Crit Rate + 10% Crit Damage
# Physical - Magic

func set_base_stats() -> void: # TODO: change name
	# TODO: temporary code
	animation = load("res://entities/players/character_animations/akirose.tres")
	if base:
		base.get_node("AnimatedSprite2D").sprite_frames = animation
		base.get_node("AnimatedSprite2D").play(&"down_idle")

	base_health = 396 # +196 (+0.98 T1)
	base_mana = 26 # +16 (+1.6 T1)
	base_stamina = 100
	base_defense = 11 # +1 (+0.2 T1)
	base_ward = 11 # +1 (+0.2 T1)
	base_strength = 14 # +4 (+0.8 T1)
	base_intelligence = 12 # +2 (+0.4 T1)
	base_speed = 0
	base_agility = 0
	base_crit_chance = 0.05 # +0.02 Crit Rate
	base_crit_damage = 0.60 # +0.10 Crit Damage
