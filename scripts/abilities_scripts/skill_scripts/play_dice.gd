extends Node2D

@onready var caster_node: EntityBase = Players.main_player
@onready var interval_timer := %Interval

const DAMAGE_TYPES: int = \
		Damage.DamageTypes.ENEMY_HIT \
		| Damage.DamageTypes.COMBAT \
		| Damage.DamageTypes.PHYSICAL \
		| Damage.DamageTypes.NO_CRITICAL

const mana_cost := 1 # 50 (temporarily changed)
const base_damage := 5

var dice_results: Array[int] = []
var dice_damage := 0.0

signal entities_chosen

func _ready():
	# disabled while selecting target
	set_physics_process(false)
	hide()

	connect(&"entities_chosen", Callable(self, "initiate_play_dice"))

	# request target entity
	Entities.request_entities([Entities.Type.ENEMIES_ON_SCREEN])
	
	if Entities.entities_available.is_empty():
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed(&"alt") and Entities.entities_available.size() != 0:
		Entities.choose_entity(Entities.target_entity_by_distance(Entities.entities_available, caster_node.position, false))
	
func initiate_play_dice(chosen_node):
	# check caster status and mana sufficiency
	if caster_node.stats.mana > mana_cost and caster_node.stats.alive:
		caster_node.stats.update_mana(-mana_cost)

		# roll 1 to 17 dice
		for i in (1 + (caster_node.stats.speed + caster_node.stats.agility) / 32):
			dice_results.append(randi() % 7)
			dice_damage = base_damage / 2.0 * dice_results[-1]
		
			# double damage for each duplicate
			dice_damage *= 2 * dice_results.count(dice_results[-1])
			
			# check for "6"
			if dice_results[-1] == 6: dice_damage *= 1.5

			# check for 5 dice duplicates
			if dice_results.count(dice_results[-1]) == 5: dice_damage *= 2

			# TODO: want to accelerate for each iteration
			interval_timer.start()
			Damage.combat_damage(dice_damage, DAMAGE_TYPES,
					caster_node.stats, chosen_node.stats)
			await interval_timer.timeout

	queue_free()

func entities_request_failed() -> void:
	queue_free()
