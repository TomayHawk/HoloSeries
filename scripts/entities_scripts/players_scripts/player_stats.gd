class_name PlayerStats extends EntityStats

var character: CharacterBase = null

# equipment variables
var weapon: Weapon = null
var headgear: Headgear = null
var chestpiece: Chestpiece = null
var leggings: Leggings = null
var accessory_1: Accessory = null
var accessory_2: Accessory = null
var accessory_3: Accessory = null

# stats variables
var experience: float = 0.0

# ultimate variables
var ultimate_gauge: float = 0.0
var max_ultimate_gauge: float = 100.0

# movement variables
var walk_speed: float = 140.0
var dash_multiplier: float = 1120.0
var dash_stamina: float = 35.0
var dash_min_stamina: float = 25.0
var dash_time: float = 0.2
var sprint_multiplier: float = 175.0
var sprint_stamina: float = 0.8
var attack_movement_reduction: float = 0.3
var fatigue: bool = false

# nexus variables
var last_node: int = -1
var unlocked_nodes: Array[int] = []
var converted_nodes: Array[Array] = []

# ..............................................................................

# STATS UPDATES

func update_health(value: float) -> void:
	super (value)
	if base: base.update_health(health)

func update_mana(value: float) -> void:
	super (value)
	if base: base.update_mana(mana)

func update_stamina(value: float) -> void:
	super (value)

	# handle fatigue
	if stamina == 0:
		fatigue = true
	elif stamina == max_stamina:
		fatigue = false

	if base: base.update_stamina(stamina)

func update_shield(value: float) -> void:
	super (value)
	if base: base.update_shield(shield)

func update_ultimate_gauge(value: float) -> void:
	if not alive: return
	ultimate_gauge = clamp(ultimate_gauge + value, 0, max_ultimate_gauge)
	if base: base.update_ultimate_gauge(ultimate_gauge)

# ..............................................................................

# SET STATS
func set_stats() -> void:
	# TODO: update level and experience
	# TODO: update entity_types
	# set base stats
	character.set_base_stats(self)

	# update base stats from nexus nodes
	for unlocked_node in unlocked_nodes:
		# TODO: currently uses Vector2 atlas locations
		var nexus_type: int = 1 # TODO: Global.nexus_types[unlocked_node]
		match nexus_type:
			1: # Health
				base_health += Global.nexus_qualities[unlocked_node]
			2: # Mana
				base_mana += Global.nexus_qualities[unlocked_node]
			3: # Defense
				base_defense += Global.nexus_qualities[unlocked_node]
			4: # Ward
				base_ward += Global.nexus_qualities[unlocked_node]
			5: # Strength
				base_strength += Global.nexus_qualities[unlocked_node]
			6: # Intelligence
				base_intelligence += Global.nexus_qualities[unlocked_node]
			7: # Speed
				base_speed += Global.nexus_qualities[unlocked_node]
			8: # Agility
				base_agility += Global.nexus_qualities[unlocked_node]
	
	# update base stamina
	base_stamina = 100.0

	# update base secondary stats
	base_weight = 1.0
	base_vision = 1.0

	# update max health, mana and stamina
	max_health = base_health
	max_mana = base_mana
	max_stamina = base_stamina

	# update basic stats
	defense = base_defense
	ward = base_ward
	strength = base_strength
	intelligence = base_intelligence
	speed = base_speed
	agility = base_agility
	crit_chance = base_crit_chance
	crit_damage = base_crit_damage

	# update secondary stats
	weight = base_weight
	vision = base_vision

	if weapon: weapon.set_stats(self)
	if headgear: headgear.set_stats(self)
	if chestpiece: chestpiece.set_stats(self)
	if leggings: leggings.set_stats(self)
	if accessory_1: accessory_1.set_stats(self)
	if accessory_2: accessory_2.set_stats(self)
	if accessory_3: accessory_3.set_stats(self)
	# TODO: update current stats based on effects
	# TODO: update 

	# update health, mana and stamina
	health = max_health
	mana = max_mana
	stamina = max_stamina

# ..............................................................................

# DEATH & REVIVE

func death() -> void:
	super ()
	fatigue = false
	if base: base.death()

func revive(value: float) -> void:
	super (value)
	if base: base.revive()
