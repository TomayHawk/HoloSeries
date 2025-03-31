extends Node2D

# TODO: need to dynamically allocate caster in case of ally/enemy casts
@onready var caster_node: Node = Players.main_player_node
@onready var caster_stats_node: Node = caster_node.character_node

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

var mana_cost: float = 4.0
var heal_percentage: float = 0.05

signal entities_chosen

func _ready():
	hide()

	connect("entities_chosen", Callable(self, "initiate_heal"))

	# request target entities
	Entities.request_entities(self, [Entities.Type.PLAYERS_PARTY_ALIVE])

	# if alt is pressed, target player with lowest health
	if Input.is_action_pressed(&"alt"):
		Entities.target_entity("health", caster_node)

func initiate_heal(chosen_node):
	# TODO: should add a variable for "player can cast spells"
	# check caster mana sufficiency and 
	if caster_stats_node.mana < mana_cost or not caster_stats_node.alive:
		queue_free()
		return
	# check caster status and mana sufficiency

	caster_stats_node.update_mana(-mana_cost)

	# heal chosen node
	Damage.combat_damage(chosen_node.character_node.max_health * heal_percentage,
			DAMAGE_TYPES, caster_stats_node, chosen_node.character_node)

	queue_free()

func ability_request_failed() -> void:
	queue_free()
