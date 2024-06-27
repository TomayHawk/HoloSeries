extends Node2D

@onready var current_nexus_player = GlobalSettings.current_main_player
@onready var unlockable_load = load("res://components/unlockables.tscn")
var unlockable_instance = null

# create array for all nexus nodes
@onready var nexus_nodes = $NexusNodes.get_children()

# [player][node]
var nodes_unlocked = [[], [], [], [], [], [], [], [], [], []]
var nodes_unlockable = [[], [], [], [], [], [], [], [], [], []]

# adjacents and second adjacents
const adjacents_index = [[ - 32, - 17, - 16, 15, 16, 32], [ - 64, - 49, - 48, - 33, - 32, - 31, - 17, - 16, - 1, 1, 15, 16, 31, 32, 33, 47, 48, 64],
						 [- 32, - 16, - 15, 16, 17, 32], [ - 64, - 48, - 47, - 33, - 32, - 31, - 16, - 15, - 1, 1, 16, 17, 31, 32, 33, 48, 49, 64]]
						 
# empty, hp, mp, def, mdef, atk, int, spd, agi
const node_type_atlas_position = [Vector2(0, 0), Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
# diamond, clover, heart, spade
const key_node_type_atlas_position = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]
# null
const null_node_type_atlas_position = Vector2(32, 0)

# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
var area_nodes = [[], [], [], [], [], [], [], [], [], [], [], []]

func _ready():
	# duplicate node_unlocked from GlobalSettings
	nodes_unlocked = GlobalSettings.global_unlocked_nodes.duplicate()

	# check for all adjacent unlockables
	var temp_adjacents = []
	var second_temp_adjacents = []

	for player in 4: if GlobalSettings.global_unlocked_players[player]: # for each unlocked player
		for node in nodes_unlocked[player]: # for each unlocked node
			# determine adjacent nodes
			if (node % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(node + temp_index)
			else: for temp_index in adjacents_index[2]: temp_adjacents.push_back(node + temp_index)

			for adjacent in adjacents_index[temp_adjacents_type]: # for each adjacent node
				if !(adjacent in nodes_unlocked[player])&&(adjacent > - 1)&&(adjacent < 767): # if node is not unlocked and node exists
					# determine second adjacent nodes
					if (adjacent % 32) < 16: for second_temp_index in adjacents_index[0]: second_temp_adjacents.push_back(adjacent + second_temp_index)
					else: for second_temp_index in adjacents_index[2]: second_temp_adjacents.push_back(adjacent + second_temp_index)

					for second_adjacent in second_temp_adjacents: # for each adjacent node to adjacent node
						# if second adjacent is unlocked, is not original node, and is not in unlockables array
						if (second_adjacent in nodes_unlocked[player])&&(second_adjacent != node)&&!(adjacent in nodes_unlockable[player]):
							nodes_unlockable[player].push_back(temp_index)

	# if nexus is empty, initiate randomizer
	if GlobalSettings.nexus_not_randomized: stat_nodes_randomizer()
	
	# update NexusPlayer and visible unlocked nodes
	update_nexus_player(current_nexus_player)

func stat_nodes_randomizer():
	var node_index = 0
	for node in nexus_nodes:

		if node.modulate == Color(1, 0, 1, 1): area_nodes[0].push_back(node_index) # white magic (pink)
		elif node.modulate == Color(1, 0.501961, 0.501961, 1): area_nodes[1].push_back(node_index) # white magic 2 (light coral)
		elif node.modulate == Color(0.501961, 0, 1, 1): area_nodes[2].push_back(node_index) # black magic (purple)
		elif node.modulate == Color(0.501961, 0, 0.501961, 1): area_nodes[3].push_back(node_index) # black magic 2 (dark magenta)
		elif node.modulate == Color(0.501961, 1, 1, 1): area_nodes[4].push_back(node_index) # summon (red)
		elif node.modulate == Color(1, 1, 0, 1): area_nodes[5].push_back(node_index) # buff (yellow)
		elif node.modulate == Color(0.501961, 1, 1, 1): area_nodes[6].push_back(node_index) # debuff (light blue)
		elif node.modulate == Color(1, 0.501961, 0, 1): area_nodes[7].push_back(node_index) # skills (orange)
		elif node.modulate == Color(0.501961, 0.501961, 0, 1): area_nodes[8].push_back(node_index) # skills 2 (olive)
		elif node.modulate == Color(0, 1, 0, 1): area_nodes[9].push_back(node_index) # physical (green)
		elif node.modulate == Color(0, 0.501961, 0, 1): area_nodes[10].push_back(node_index) # physical 2 (dark green)
		elif node.modulate == Color(0, 0.501961, 1, 1): area_nodes[11].push_back(node_index) # tank (blue)
		
		nexus_nodes[node_index].modulate = Color(0.25, 0.25, 0.25, 1)
		node_index += 1

	##### should be "null" instead
	var temp_area_rand_type = [[]]
	
	var temp_rand_index = []
	# HP, MP, DEF, MDEF, ATK, INT, SPD, AGI
	var temp_rand_weight = [3, 3, 1, 1, 1, 1, 1, 1,
							3, 5, 1, 2, 1, 3, 1, 1,
							3, 2, 1, 1, 1, 1, 1, 1,
							3, 2, 1, 1, 1, 1, 1, 1,
							3, 1, 1, 1, 2, 2, 1, 1,
							5, 2, 3, 1, 3, 1, 2, 2]
	var temp_value = [20, 20, 5, 6, 2, 5, 3, 3,
					  20, 30, 4, 8, 3, 15, 3, 3,
					  18, 10, 6, 4, 5, 3, 3, 3,
					  14, 8, 3, 3, 4, 4, 2, 2,
					  20, 6, 4, 6, 8, 8, 6, 6,
					  30, 8, 15, 6, 15, 3, 8, 8]
	
	var temp_texture = null
	var temp_texture_region = null
	
	###############################################
	for node_area in 6: for empty_nodes_in_area in [696969669699]:
		temp_area_rand_type[node_area].push_back(node_type_atlas_position[0])
	
	for node_type_and_area in 48:
		temp_rand_index[node_type_and_area].push_back(randf_range( - 1, 1))
		for i in 3: temp_rand_index[node_type_and_area] += randf_range( - 1, 1)
		temp_rand_index[node_type_and_area] = temp_value[node_type_and_area] + round(temp_rand_index[node_type_and_area] * temp_rand_weight[node_type_and_area] / 4)
		for i in temp_rand_index[node_type_and_area]: temp_area_rand_type[node_type_and_area / 8].push_back(node_type_atlas_position[node_type_and_area % 8 + 2])
		
	for i in 6:
		##### shuffle temp_area_rand_type[i]
		for j in white_magic_area.size():
			temp_texture = nexus_nodes[node_index].texture_normal
			temp_texture_region = temp_texture.get_region()
			temp_texture.set_region(Rect2([temp_area_rand_type[i][j]], temp_texture_region.size))
		for area_node_index in white_magic_area:
		temp_texture = nexus_nodes[node_index].texture_normal
		temp_texture_region = temp_texture.get_region()
		temp_texture.set_region(Rect2([temp_area_rand_type[i][j]], temp_texture_region.size))
		##### size should be changed to int later
	
	for node_index in temp_white_magic:
		temp_texture = nexus_nodes[node_index].texture_normal
		temp_texture_region = temp_texture.get_region()
		temp_texture.set_region(Rect2([temp_area_rand_type[i][j]], temp_texture_region.size))

func update_nexus_player(player):
	current_nexus_player = player

	# disable all textures
	for node in nexus_nodes:
		pass # #### node.modulate = Color(0.25, 0.25, 0.25, 1)

	# update unlocked textures
	for node_index in nodes_unlocked[current_nexus_player]:
		pass # #### nexus_nodes[node_index].modulate = Color(1, 1, 1, 1)

	# clear UnlockableNodes control
	for past_unlockable_nodes in get_node("UnlockableNodes").get_children():
		past_unlockable_nodes.queue_free()

	# update unlockable textures
	for node_index in nodes_unlockable[current_nexus_player]:
		unlockable_instance = unlockable_load.instantiate()
		get_node("UnlockableNodes").add_child(unlockable_instance)
		unlockable_instance.position = nexus_nodes[node_index].position

func unlock_node(node):
	if !(node in nodes_unlocked[current_nexus_player]):
		nodes_unlocked[current_nexus_player].push_back(node)
		nexus_nodes[node].modulate = Color(1, 1, 1, 1)

func exit_nexus():
	GlobalSettings.global_unlocked_nodes = nodes_unlocked.duplicate()

	##### scene change
