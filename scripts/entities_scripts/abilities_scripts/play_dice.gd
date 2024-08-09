extends Node2D

@onready var caster_node := GlobalSettings.current_main_player_node

var autoaim = preload("res://scripts/entities_scripts/abilities_scripts/abilities_function/autoaim_closest_enemy.gd")
var require_mana = 50
var base_damage = 5



# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalSettings.request_entities(self, "initiate_playdice", 1, "all_enemies_on_screen")
	if GlobalSettings.entities_available.size() == 0: queue_free()
	
	# disabled while selecting target
	hide()
	set_physics_process(false)
	
	# if alt is pressed, auto-aim closest enemy
	if Input.is_action_pressed("alt") && GlobalSettings.entities_available.size() != 0:
		autoaim.auto_aim(position)
	
func initiate_playdice(chosen_node):
	#check mana sufficiency
	if caster_node.player_stats_node.mana < require_mana || !caster_node.player_stats_node.alive:
		queue_free()
	else:
		caster_node.player_stats_node.update_mana(-require_mana)
		# Me thinking either fixed damage or level up increase damage
		#var temp_damage = CombatEntitiesComponent.magic_damage_calculator(damage, caster_node.player_stats_node, chosen_node.enemy_stats_node)
		#chosen_node.enemy_stats_node.update_health(-temp_damage[0], temp_damage[1], Vector2.ZERO, 0)
		
		var damage = damage()
		#fixed damage
		chosen_node.enemy_stats_node.update_health(-damage, [], Vector2.ZERO, 0)
		queue_free()
		
func damage():
	var dice = randi()%20 #d20
	var damage
	print("value: ", dice)
	
	### here dice animation from 0 to 19, 20 side dice
	if dice == 0: #dice roll 1, critical missed
		damage = 0
	else:
		damage = base_damage * (dice+1)
	
	if dice == 19: # critical hit
		damage = pow(damage, 2)
		
	return damage
