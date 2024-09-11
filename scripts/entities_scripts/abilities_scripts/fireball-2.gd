extends CharacterBody2D

@onready var caster_node := GlobalSettings.current_main_player_node
@onready var damage_stats_multiplier: float = 1 + (GlobalSettings.current_main_player_node.player_stats_node.intelligence / 500)

const damage := 10

func _ready():
	# disabled while selecting target
	set_physics_process(false)
	hide()
	
	# request target entity
	GlobalSettings.request_entities(self, "initiate_fireball", 1, "all_enemies_on_screen")
	
	if GlobalSettings.entities_available.size() == 0 && GlobalSettings.locked_enemy_node == null:
		queue_free()
	# if alt is pressed, auto-aim closest enemy
	elif Input.is_action_pressed("alt") && GlobalSettings.entities_available.size() != 0:
		CombatEntitiesComponent.target_entity("distance_least", caster_node)

# run after entity selection with GlobalSettings.choose_entities()
func initiate_fireball(chosen_node):
		# begin despawn timer
		$AnimatedSprite2D.play("shoot")
		set_physics_process(true)
		time_left_node.start()
		show()


