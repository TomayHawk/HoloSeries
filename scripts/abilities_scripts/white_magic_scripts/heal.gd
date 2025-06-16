extends Node

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.HEAL \
		| Damage.DamageTypes.MAGIC \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_MISS

var mana_cost: float = 4.0
var heal_percentage: float = 0.05

# TODO: need to dynamically allocate caster in case of ally/enemy casts (APPLIES TO ALL ABILITIES)
@onready var caster_node: EntityBase = Players.main_player
@onready var caster_stats_node: EntityStats = caster_node.character

func _ready() -> void:
	# request target entity
	Entities.entities_request_ended.connect(entity_chosen, CONNECT_ONE_SHOT)
	Entities.request_entities([Entities.Type.PLAYERS_ALIVE])

	# if alt is pressed, target player with lowest health
	if Input.is_action_pressed(&"alt"):
		Entities.choose_entity(Entities.target_entity_by_stats(Entities.entities_available, &"health", false))

func entity_chosen(chosen_nodes: Array[EntityBase]) -> void:
	var target_node: EntityBase = null if chosen_nodes.is_empty() else chosen_nodes[0]
	# TODO: should add a variable for "player can cast spells"
	# heal if node chosen, caster is alive and caster has enough mana
	if target_node and caster_stats_node.alive and caster_stats_node.mana >= mana_cost:
		caster_stats_node.update_mana(-mana_cost)
		# heal chosen node
		Damage.combat_damage(target_node.character.max_health * heal_percentage,
				DAMAGE_TYPES, caster_stats_node, target_node.character)

	queue_free()
