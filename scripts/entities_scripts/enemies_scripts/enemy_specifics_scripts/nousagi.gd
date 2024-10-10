extends CharacterBody2D

@onready var enemies_node := get_parent()
@onready var base_enemy_node := %BaseEnemy

@onready var animation_node := %Animation
@onready var navigation_agent_node := %BaseEnemy/NavigationAgent2D
@onready var attack_cooldown_node := %BaseEnemy/AttackCooldown
@onready var summon_cooldown_node := %SummonCooldown
@onready var knockback_timer_node := %BaseEnemy/KnockbackTimer

@onready var nousagi_load := load("res://entities/enemies/enemy_specifics/nousagi.tscn")

var speed := 4500.0

# animation variables
var current_animation := ""
var current_frame := 0
var last_frame := 1

# combat variables
var attack_ready := true
var summon_ready := false
var taking_knockback := false

# direction variables
var move_direction := Vector2.ZERO
var attack_direction := Vector2.ZERO

# combat status variables
var knockback_direction := Vector2.ZERO
var knockback_weight := 0.0
var invincible := false

# temporary variables
var targetable_player_nodes: Array[Node] = []
var target_player_node: Node = null
var target_player_health := INF
var nousagi_instance: Node = null

func _ready():
	animation_node.play("walk")

func _physics_process(delta):
	# get current animation and current animation frame information
	current_animation = animation_node.get_animation()
	current_frame = animation_node.get_frame()
	
	# choose a player if player exists in detection area
	if base_enemy_node.players_exist_in_detection_area: choose_player()

	# if on first physics game tick of current animation frame
	if current_frame != last_frame:
		if current_frame == 0:
			velocity = Vector2(0, 0)

			# remove all dead players from detection arrays
			for player_node in base_enemy_node.player_nodes_in_detection_area:
				if !player_node.player_stats_node.alive:
					base_enemy_node._on_detection_area_body_exited(player_node)
					base_enemy_node._on_attack_area_body_exited(player_node)
			
			# attack or idle if any player in attack area
			if base_enemy_node.players_exist_in_attack_area:
				animation_node.play("idle")
				if attack_ready:
					# summon nousagi (1 / 3 or 10.00%)
					if summon_ready && randi() % 10 == 0:
						summon_nousagi()
					else:
						animation_node.play("attack")
			# else determine move direction
			else:
				# move towards player if any player in detection area
				if base_enemy_node.players_exist_in_detection_area:
					navigation_agent_node.target_position = target_player_node.position
					move_direction = to_local(navigation_agent_node.get_next_path_position()).normalized()
				# else move in a random direction
				else:
					move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				animation_node.play("walk")
				animation_node.flip_h = move_direction.x < 0
		elif current_frame == 3:
			if current_animation == "attack":
				# attack player
				if base_enemy_node.players_exist_in_attack_area:
					attack_direction = (target_player_node.position - position).normalized()
					var damage = CombatEntitiesComponent.physical_damage_calculator(13, base_enemy_node, target_player_node.player_stats_node)
					target_player_node.player_stats_node.update_health(-damage[0], damage[1], attack_direction, 0.4) # attack player (damage)
					animation_node.flip_h = attack_direction.x < 0
				attack_cooldown_node.start(randf_range(1, 3))
				attack_ready = false
			elif current_animation == "walk":
				velocity = move_direction * speed * delta

		if base_enemy_node.players_exist_in_attack_area: velocity = Vector2(0, 0)

	# check knockback
	if taking_knockback:
		animation_node.play("idle")
		velocity = knockback_direction * 12000 * delta * (1 - (0.4 - knockback_timer_node.get_time_left()) / 0.4) * knockback_weight
	# animation check outside animation frame update
	elif current_animation == "idle":
		# face targeet player
		if target_player_node != null:
			animation_node.flip_h = (target_player_node.position - position).x < 0
		# switch to attack when ready
		if base_enemy_node.players_exist_in_attack_area && attack_ready:
			animation_node.play("attack")
		# switch to walk when outside attack mode
		elif !base_enemy_node.players_exist_in_attack_area:
			animation_node.play("walk")

	last_frame = current_frame
	move_and_slide()

func choose_player():
	target_player_node = null
	target_player_health = INF

	# determine targetable player nodes
	if base_enemy_node.players_exist_in_attack_area:
		targetable_player_nodes = base_enemy_node.player_nodes_in_attack_area.duplicate()
	else:
		targetable_player_nodes = base_enemy_node.player_nodes_in_detection_area.duplicate()

	# target player with lowest health
	for player_node in targetable_player_nodes:
		if player_node.player_stats_node.health < target_player_health:
			target_player_health = player_node.player_stats_node.health
			target_player_node = player_node

func summon_nousagi():
	# create an instance of nousagi in enemies node
	nousagi_instance = nousagi_load.instantiate()
	enemies_node.add_child(nousagi_instance)
	nousagi_instance.position = position + Vector2(5 * randf_range(-1, 1), 5 * randf_range(-1, 1)) * 5
	
	# start cooldown
	attack_cooldown_node.start(randf_range(2, 3))
	attack_ready = false
	summon_cooldown_node.start(randf_range(15, 20))
	summon_ready = false

func _on_summon_timer_timeout():
	summon_ready = true
