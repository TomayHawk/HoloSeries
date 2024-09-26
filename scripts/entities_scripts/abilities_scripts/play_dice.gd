extends Node2D

@onready var caster_node := GlobalSettings.current_main_player_node
@onready var interval_timer := $Interval

const mana_cost := 1 # 50 (temporarily changed)
const base_damage := 5

var dice_results: Array[int] = []
var dice_damage := 0.0

func _ready():
	# disabled while selecting target
	set_physics_process(false)
	hide()

	# request target entity
	CombatEntitiesComponent.request_entities(self, "initiate_play_dice", 1, "all_enemies_on_screen")
	
	if CombatEntitiesComponent.entities_available.size() == 0:
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed("alt") && CombatEntitiesComponent.entities_available.size() != 0:
		CombatEntitiesComponent.target_entity("distance_least", caster_node)
	
func initiate_play_dice(chosen_node):
	# check caster status and mana sufficiency
	if caster_node.player_stats_node.mana > mana_cost && caster_node.player_stats_node.alive:
		caster_node.player_stats_node.update_mana(-mana_cost)

		# roll 1 to 17 dice
		for i in (1 + (caster_node.player_stats_node.speed + caster_node.player_stats_node.agility) / 32):
			dice_results.push_back(randi() % 7)
			dice_damage = base_damage / 2.0 * dice_results[-1]
		
			# double damage for each duplicate
			dice_damage *= 2 * dice_results.count(dice_results[-1])
			
			# check for "6"
			if dice_results[-1] == 6: dice_damage *= 1.5

			# check for 5 dice duplicates
			if dice_results.count(dice_results[-1]) == 5: dice_damage *= 2

			##### want to accelerate for each iteration
			interval_timer.start()
			chosen_node.enemy_stats_node.update_health(-dice_damage, [], Vector2.ZERO, 0.0)
			await interval_timer.timeout

	queue_free()
