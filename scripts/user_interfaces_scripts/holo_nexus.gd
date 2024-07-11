extends Node2D

@onready var current_nexus_player = GlobalSettings.current_main_player_node.character_specifics_node.character_index
@onready var unlockable_load = load("res://resources/nexus_unlockables.tscn")
var unlockable_instance = null

# create array for all nexus nodes
@onready var nexus_nodes = $NexusNodes.get_children()

@onready var nexus_player_node = $NexusPlayer

var unlocked_players = [true, true, false, false]
var last_node = [167, 0, 0, 0]

# [player][node]
var nodes_unlocked = [[], [], [], [], [], [], [], [], [], []]
var nodes_unlockable = [[], [], [], [], [], [], [], [], [], []]

# adjacents and second adjacents
const adjacents_index = [[ - 32, - 17, - 16, 15, 16, 32], [ - 32, - 16, - 15, 16, 17, 32]]

# empty
const empty_node_atlas_position = Vector2(0, 0)
# null
const null_node_atlas_position = Vector2(32, 0)
# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
const stats_node_atlas_position = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
# diamond, clover, heart, spade
const key_node_atlas_position = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]

# ability nodes
var ability_nodes = []

# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
var area_nodes = [[], [], [], [], [], [], [], [], [], [], [], []]
var key_nodes = [[], [], [], []]
var null_nodes = []

func _ready():
	# duplicate node_unlocked from GlobalSettings
	nodes_unlocked = GlobalSettings.unlocked_nodes.duplicate()

	# check for all adjacent unlockables
	for player_index in 4: if GlobalSettings.unlocked_players[player_index]: # for each unlocked player
		for node in nodes_unlocked[player_index]: # for each unlocked node
			# determine adjacent nodes
			var temp_adjacents = []
			if (node % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(node + temp_index)
			else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(node + temp_index)

			for adjacent in temp_adjacents: # for each adjacent node
				if !(adjacent in nodes_unlocked[player_index])&&(adjacent > - 1)&&(adjacent < 767): # if node is not unlocked and node exists
					# determine second adjacent nodes
					var second_temp_adjacents = []
					if (adjacent % 32) < 16: for second_temp_index in adjacents_index[0]: second_temp_adjacents.push_back(adjacent + second_temp_index)
					else: for second_temp_index in adjacents_index[1]: second_temp_adjacents.push_back(adjacent + second_temp_index)

					for second_adjacent in second_temp_adjacents: # for each adjacent node to adjacent node
						# if second adjacent is unlocked, is not original node, and is not in unlockables array
						if (second_adjacent in nodes_unlocked[player_index])&&(second_adjacent != node)&&!(adjacent in nodes_unlockable[player_index]):
							nodes_unlockable[player_index].push_back(adjacent)

	# if nexus is empty, initiate randomizer
	if GlobalSettings.nexus_not_randomized: stat_nodes_randomizer()
	
	for node in nexus_nodes:
		if node.texture.region.position == Vector2(32, 0): null_nodes.push_back(node.get_index()) # null
		elif node.texture.region.position.y == 96: # keys
			if node.texture.region.position.x == 0: key_nodes[0].push_back(node.get_index()) # diamond
			elif node.texture.region.position.x == 32: key_nodes[1].push_back(node.get_index()) # clover
			elif node.texture.region.position.x == 64: key_nodes[2].push_back(node.get_index()) # heart
			elif node.texture.region.position.x == 96: key_nodes[3].push_back(node.get_index()) # spade

	for player in 4:
		for node_index in nodes_unlockable[player].duplicate():
			if node_index in null_nodes:
				nodes_unlockable[player].erase(node_index)

	# update NexusPlayer and visible unlocked nodes
	update_nexus_player(current_nexus_player)

func stat_nodes_randomizer():
	GlobalSettings.nexus_not_randomized = false

	var node_index = 0
	for node in nexus_nodes:

		if node.modulate == Color(1, 0, 1, 1): area_nodes[0].push_back(node_index) # white magic (pink)
		elif node.modulate == Color(1, 0.501961, 0.501961, 1): area_nodes[1].push_back(node_index) # white magic 2 (light coral)
		elif node.modulate == Color(0.501961, 0, 1, 1): area_nodes[2].push_back(node_index) # black magic (purple)
		elif node.modulate == Color(0.501961, 0, 0.501961, 1): area_nodes[3].push_back(node_index) # black magic 2 (dark magenta)
		elif node.modulate == Color(1, 0, 0, 1): area_nodes[4].push_back(node_index) # summon (red)
		elif node.modulate == Color(1, 1, 0, 1): area_nodes[5].push_back(node_index) # buff (yellow)
		elif node.modulate == Color(0.501961, 1, 1, 1): area_nodes[6].push_back(node_index) # debuff (light blue)
		elif node.modulate == Color(1, 0.501961, 0, 1): area_nodes[7].push_back(node_index) # skills (orange)
		elif node.modulate == Color(0.501961, 0.501961, 0, 1): area_nodes[8].push_back(node_index) # skills 2 (olive)
		elif node.modulate == Color(0, 1, 0, 1): area_nodes[9].push_back(node_index) # physical (green)
		elif node.modulate == Color(0, 0.501961, 0, 1): area_nodes[10].push_back(node_index) # physical 2 (dark green)
		elif node.modulate == Color(0, 0.501961, 1, 1): area_nodes[11].push_back(node_index) # tank (blue)
		elif node.modulate == Color(1, 1, 1, 1): ability_nodes.push_back(node_index) # ability nodes

		node_index += 1
	
	# HP, MP, DEF, SHD, ATK, INT, SPD, AGI, EMPTY
	# randomizer base number
	var rand_amount = [[6, 11, 2, 3, 2, 3, 2, 2],
					  [2, 4, 1, 1, 0, 2, 0, 0],
					  [9, 18, 3, 4, 3, 12, 3, 3],
					  [3, 5, 1, 2, 1, 3, 1, 1],
					  [4, 4, 2, 2, 1, 3, 1, 1],
					  [11, 8, 3, 3, 4, 4, 3, 3],
					  [6, 8, 2, 3, 2, 4, 2, 2],
					  [11, 6, 2, 4, 4, 3, 3, 3],
					  [3, 2, 1, 0, 1, 1, 1, 1],
					  [13, 3, 4, 3, 12, 2, 3, 3],
					  [5, 1, 2, 1, 5, 0, 2, 2],
					  [8, 1, 4, 2, 2, 1, 0, 0]]
	# randomizer multiplier
	var rand_weight = [[2, 3, 1, 1, 1, 1, 1, 1],
					   [1, 1, 0, 0, 0, 1, 0, 0],
					   [2, 3, 1, 1, 1, 3, 1, 1],
					   [1, 1, 0, 1, 0, 1, 0, 0],
					   [1, 1, 1, 1, 0, 1, 0, 0],
					   [3, 2, 1, 1, 1, 1, 1, 1],
					   [2, 2, 1, 1, 1, 1, 1, 1],
					   [3, 2, 1, 1, 1, 1, 1, 1],
					   [1, 1, 0, 0, 0, 0, 0, 0],
					   [3, 1, 1, 1, 3, 1, 1, 1],
					   [1, 0, 1, 0, 1, 0, 1, 1],
					   [2, 0, 1, 1, 1, 0, 0, 0]]
	
	var rand_result = [[], [], [], [], [], [], [], [], [], [], [], []]
	var area_rand_type = [[], [], [], [], [], [], [], [], [], [], [], []]
	var empty_type = 0
	
	for rand_area in 12: # for each area type
		empty_type = area_nodes[rand_area].size() # set number of empty nodes to size of area
		for rand_type in 8: # for each stat node type
			# create x stat node type, where x is the base amount + a random weighted flactuation
			rand_result[rand_area].push_back(rand_amount[rand_area][rand_type] + round(rand_weight[rand_area][rand_type] * (randf_range( - 1, 1) + randf_range( - 1, 1) + randf_range( - 1, 1) + randf_range( - 1, 1)) / 4)) #
			empty_type -= rand_result[rand_area][rand_type] # reduce the number of empty nodes by x
			# assign x variables to texture region based on stat node type
			for rand_number in rand_result[rand_area][rand_type]:
				area_rand_type[rand_area].push_back(stats_node_atlas_position[rand_type])
			
		# assign y variables to texture region of empty node type, where y is the remaining unchanged nodes
		for number in empty_type:
			area_rand_type[rand_area].push_back(empty_node_atlas_position)

		# shuffle area array
		area_rand_type[rand_area].shuffle()

		for array_index in area_nodes[rand_area].size():
			# temp_texture_region = temp_texture.get_region()
			nexus_nodes[area_nodes[rand_area][array_index]].texture.region = Rect2(area_rand_type[rand_area][array_index], Vector2(32, 32))
		
		var empty_replacer = []

		for temp_node_index in area_nodes[rand_area]:
			if nexus_nodes[temp_node_index].texture.region == Rect2(Vector2(0, 0), Vector2(32, 32)):
				empty_replacer.push_back(temp_node_index)

		empty_replacer.shuffle()

		var temp_adjacents = []
		var same_count = 0

		for i in 5:
			for temp_node_index in area_nodes[rand_area]:
				temp_adjacents.clear()
				same_count = 0

				# determine adjacent nodes
				if (temp_node_index % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
				else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)

				for adjacent in temp_adjacents: # for each adjacent node
					# if adjacent node exists and has a same type neighbour, add 1 to count
					if (adjacent > - 1)&&(adjacent < 767)&&nexus_nodes[temp_node_index].texture.region == nexus_nodes[adjacent].texture.region:
						same_count += 1

				# if more than 1 same type neighbour
				if same_count > 0:
					# replace an empty node with this node type, and this node becomes empty
					nexus_nodes[empty_replacer.pop_back()].texture.region = nexus_nodes[temp_node_index].texture.region
					nexus_nodes[temp_node_index].texture.region = Rect2(Vector2(0, 0), Vector2(32, 32))

					empty_replacer.push_back(temp_node_index)
					empty_replacer.shuffle()

func update_nexus_player(player):
	current_nexus_player = player

	# disable all textures
	for node in nexus_nodes:
		node.modulate = Color(0.25, 0.25, 0.25, 1)

	# update null node textures
	for node_index in null_nodes:
		nexus_nodes[node_index].modulate = Color(0.5, 0.5, 0.5, 1)

	# update unlocked textures
	for node_index in nodes_unlocked[current_nexus_player]:
		nexus_nodes[node_index].modulate = Color(1, 1, 1, 1)

	# update key textures
	for key_type in 4:
		for node_index in key_nodes[key_type]:
			nexus_nodes[node_index].modulate = Color(0.33, 0.33, 0.33, 1)

	# clear unlockable textures
	for past_unlockable_nodes in get_node("UnlockableNodes").get_children():
		past_unlockable_nodes.queue_free()

	# update unlockable textures
	for node_index in nodes_unlockable[current_nexus_player]:
		unlockable_instance = unlockable_load.instantiate()
		get_node("UnlockableNodes").add_child(unlockable_instance)
		unlockable_instance.position = nexus_nodes[node_index].position
	
	nexus_player_node.position = nexus_nodes[last_node[current_nexus_player]].position + Vector2(16, 16)
	nexus_player_node.get_node("Sprite2D").show()
	nexus_player_node.get_node("Sprite2D2").hide()

func unlock_node():
	if last_node[current_nexus_player] in nodes_unlockable[current_nexus_player]:
		nodes_unlocked[current_nexus_player].push_back(last_node[current_nexus_player])
		nodes_unlockable[current_nexus_player].erase(last_node[current_nexus_player])

		for unlockable in $UnlockableNodes.get_children():
			if unlockable.position == nexus_nodes[last_node[current_nexus_player]].position:
				unlockable.queue_free()

		nexus_nodes[last_node[current_nexus_player]].modulate = Color(1, 1, 1, 1)

		var temp_adjacents = []

		if (last_node[current_nexus_player] % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(last_node[current_nexus_player] + temp_index)
		else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(last_node[current_nexus_player] + temp_index)

		for adjacent in temp_adjacents: # for each adjacent node
			if !(adjacent in nodes_unlocked[current_nexus_player])&&(adjacent > - 1)&&(adjacent < 767): # if node is not unlocked and node exists
				# determine second adjacent nodes
				var second_temp_adjacents = []
				if (adjacent % 32) < 16: for second_temp_index in adjacents_index[0]: second_temp_adjacents.push_back(adjacent + second_temp_index)
				else: for second_temp_index in adjacents_index[1]: second_temp_adjacents.push_back(adjacent + second_temp_index)

				for second_adjacent in second_temp_adjacents: # for each adjacent node to adjacent node
					# if second adjacent is unlocked, is not original node, and is not in unlockables array
					if (second_adjacent in nodes_unlocked[current_nexus_player])&&(second_adjacent != last_node[current_nexus_player])&&!(adjacent in nodes_unlockable[current_nexus_player]):
						nodes_unlockable[current_nexus_player].push_back(adjacent)
						unlockable_instance = unlockable_load.instantiate()
						get_node("UnlockableNodes").add_child(unlockable_instance)
						unlockable_instance.position = nexus_nodes[last_node[current_nexus_player]].position

func exit_nexus():
	GlobalSettings.unlocked_nodes = nodes_unlocked.duplicate()

	# for each unlocked player
	for player_index in 4: if GlobalSettings.unlocked_players[player_index]:
		# clear unlocked nodes lists
		GlobalSettings.unlocked_ability_nodes[player_index].clear()
		GlobalSettings.unlocked_stats_nodes[player_index] = [0, 0, 0, 0, 0, 0, 0, 0]
		# for each unlocked node
		for unlocked_index in nodes_unlocked[player_index]:
			# if node is an ability, add node index to unlocked abilities list
			if unlocked_index in ability_nodes:
				GlobalSettings.unlocked_ability_nodes[player_index].push_back(unlocked_index)
			# else add count to respective unlocked stats node type
			else:
				for texture_region_index in stats_node_atlas_position.size():
					if nexus_nodes[unlocked_index].texture.region.position == stats_node_atlas_position[texture_region_index]:
						GlobalSettings.unlocked_stats_nodes[player_index][texture_region_index] += 1
						break
	
	# change scene
	GlobalSettings.game_paused = false
	GlobalSettings.game_options_node.hide()
	GlobalSettings.combat_ui_node.show()
	GlobalSettings.show()
	GlobalSettings.current_scene_node.show()
	get_tree().paused = false
	queue_free()
