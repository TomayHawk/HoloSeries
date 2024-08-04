extends Node2D

# create array for all nexus nodes
@onready var nexus_nodes := $NexusNodes.get_children()
@onready var nexus_player_node := $NexusPlayer
@onready var nexus_ui_node := $HoloNexusUI
@onready var current_nexus_player = GlobalSettings.current_main_player_node.character_specifics_node.character_index
@onready var unlockable_load := load("res://resources/nexus_unlockables.tscn")
var unlockable_instance: Node = null

# character information
@onready var last_nodes: Array[int] = GlobalSettings.nexus_last_nodes.duplicate()
@onready var nodes_unlocked: Array[Array] = GlobalSettings.nexus_nodes_unlocked.duplicate()
@onready var nodes_unlockable: Array[Array] = GlobalSettings.nexus_nodes_unlockable.duplicate()
@onready var nodes_quality: Array[int] = GlobalSettings.nexus_nodes_quality.duplicate()
@onready var nodes_converted: Array[Array] = GlobalSettings.nexus_nodes_converted.duplicate()
@onready var nodes_converted_type: Array[Array] = GlobalSettings.nexus_nodes_converted_type.duplicate()
@onready var nodes_converted_quality: Array[Array] = GlobalSettings.nexus_nodes_converted_quality.duplicate()

# nexus atlas positions
# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
# diamond, clover, heart, spade
# skills, white magic, black magic
const empty_node_atlas_position := Vector2(0, 0)
const null_node_atlas_position := Vector2(32, 0)
const stats_node_atlas_position: Array[Vector2] = [Vector2(0, 32), Vector2(32, 32), Vector2(64, 32), Vector2(96, 32), Vector2(0, 64), Vector2(32, 64), Vector2(64, 64), Vector2(96, 64)]
const key_node_atlas_position: Array[Vector2] = [Vector2(0, 96), Vector2(32, 96), Vector2(64, 96), Vector2(96, 96)]
const ability_node_atlas_position: Array[Vector2] = [Vector2(64, 0), Vector2(96, 0), Vector2(128, 0)]

const default_stats_qualities := {
	0: [[200, 200, 300], [200, 200, 300, 300, 300, 400], [300, 300, 400]],
	1: [[10, 10, 20], [10, 10, 20, 20, 40], [20, 20, 40]],
	2: [[5, 10], [5, 10, 10, 15], [10, 15]],
	3: [[5, 10], [5, 10, 10, 15], [10, 15]],
	4: [[5, 5, 5, 10], [5, 10], [10]],
	5: [[5, 5, 5, 10], [5, 10], [10]],
	6: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]],
	7: [[1, 1, 2, 2, 2, 3], [1, 2, 3, 3, 4], [3, 4]]
}

const converted_stats_qualities := [400, 40, 15, 15, 20, 20, 4, 4]

# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
# HP, MP, DEF, SHD, ATK, INT, SPD, AGI
const default_area_stats_qualities := [[0, 0, 0, 0, 0, 0, 0, 0],
									   [1, 2, 0, 2, 0, 2, 1, 1],
									   [0, 0, 0, 0, 0, 0, 0, 0],
									   [1, 2, 0, 2, 0, 2, 1, 1],
									   [0, 0, 0, 0, 0, 0, 0, 0],
									   [0, 0, 0, 0, 0, 0, 1, 1],
									   [0, 0, 0, 0, 0, 0, 1, 1],
									   [0, 0, 0, 0, 0, 0, 0, 0],
									   [1, 1, 1, 1, 1, 1, 2, 2],
									   [0, 0, 0, 0, 0, 0, 0, 0],
									   [2, 1, 2, 0, 2, 0, 1, 1],
									   [1, 0, 1, 1, 0, 0, 0, 0]]

# ability nodes
var ability_nodes: Array[int] = []

# non-stats nodes
var null_nodes: Array[int] = []
var key_nodes: Array[Array] = [[], [], [], []]
var skill_nodes: Array[int] = []
var white_magic_nodes: Array[int] = []
var black_magic_nodes: Array[int] = []

# adjacent node indices
const adjacents_index: Array[Array] = [[-32, -17, -16, 15, 16, 32], [-32, -16, -15, 16, 17, 32]]

# temporary variables
var node_index := 0

func _ready():
	# update camera settings
	GlobalSettings.current_camera_node = nexus_player_node.get_node("Camera2D")
	GlobalSettings.current_camera_node.zoom = Vector2(1.0, 1.0)
	GlobalSettings.target_zoom = Vector2(1.0, 1.0)
	GlobalSettings.mouse_in_zoom_area = true

	# toggle nexus inputs
	GlobalSettings.nexus_inputs_available = true
	GlobalSettings.nexus_character_selector_node = get_node("HoloNexusUI/NexusCharacterSelector")

	# update board
	if GlobalSettings.nexus_not_randomized:
		stat_nodes_randomizer()
	else:
		node_index = 0
		for node in nexus_nodes:
			if node.texture.region.position == empty_node_atlas_position:
				node.texture.region.position = GlobalSettings.nexus_default_atlas_positions[node_index]
			node_index += 1

	# update current player and allies in character selector
	update_nexus_player(current_nexus_player)
	nexus_ui_node.update_character_selector()

func stat_nodes_randomizer():
	GlobalSettings.nexus_not_randomized = false

	# white magic, white magic 2, black magic, black magic 2, summon, buff, debuff, skills, skills 2, physical, physical 2, tank
	var area_nodes: Array[Array] = [[], [], [], [], [], [], [], [], [], [], [], []]

	node_index = 0
	for temp_node in nexus_nodes:
		if temp_node.modulate == Color(1, 0, 1, 1): area_nodes[0].push_back(node_index) # white magic (pink)
		elif temp_node.modulate == Color(1, 0.501961, 0.501961, 1): area_nodes[1].push_back(node_index) # white magic 2 (light coral)
		elif temp_node.modulate == Color(0.501961, 0, 1, 1): area_nodes[2].push_back(node_index) # black magic (purple)
		elif temp_node.modulate == Color(0.501961, 0, 0.501961, 1): area_nodes[3].push_back(node_index) # black magic 2 (dark magenta)
		elif temp_node.modulate == Color(1, 0, 0, 1): area_nodes[4].push_back(node_index) # summon (red)
		elif temp_node.modulate == Color(1, 1, 0, 1): area_nodes[5].push_back(node_index) # buff (yellow)
		elif temp_node.modulate == Color(0.501961, 1, 1, 1): area_nodes[6].push_back(node_index) # debuff (light blue)
		elif temp_node.modulate == Color(1, 0.501961, 0, 1): area_nodes[7].push_back(node_index) # skills (orange)
		elif temp_node.modulate == Color(0.501961, 0.501961, 0, 1): area_nodes[8].push_back(node_index) # skills 2 (olive)
		elif temp_node.modulate == Color(0, 1, 0, 1): area_nodes[9].push_back(node_index) # physical (green)
		elif temp_node.modulate == Color(0, 0.501961, 0, 1): area_nodes[10].push_back(node_index) # physical 2 (dark green)
		elif temp_node.modulate == Color(0, 0.501961, 1, 1): area_nodes[11].push_back(node_index) # tank (blue)
		elif temp_node.modulate == Color(1, 1, 1, 1): ability_nodes.push_back(node_index) # ability nodes
		node_index += 1
	
	# HP, MP, DEF, SHD, ATK, INT, SPD, AGI, EMPTY
	# randomizer base number
	var area_amount = [[6, 11, 2, 5, 2, 6, 2, 2],
					   [3, 4, 1, 2, 0, 2, 0, 0],
					   [11, 18, 3, 4, 3, 10, 3, 3],
					   [3, 6, 1, 2, 1, 3, 1, 1],
					   [4, 4, 1, 1, 1, 4, 1, 1],
					   [11, 8, 3, 3, 5, 4, 3, 3],
					   [6, 8, 2, 2, 2, 4, 2, 2],
					   [11, 7, 3, 2, 5, 3, 3, 3],
					   [3, 2, 1, 0, 2, 1, 1, 1],
					   [13, 4, 3, 2, 9, 1, 3, 3],
					   [5, 1, 2, 1, 4, 0, 2, 2],
					   [8, 2, 3, 1, 2, 1, 0, 0]]

	# randomizer weight
	var rand_weight = [[2, 3, 1, 1, 1, 2, 1, 1],
					   [1, 1, 0, 1, 0, 1, 0, 0],
					   [3, 5, 1, 1, 1, 3, 1, 1],
					   [1, 2, 0, 1, 0, 1, 0, 0],
					   [1, 1, 0, 0, 0, 1, 0, 0],
					   [3, 2, 1, 1, 2, 1, 1, 1],
					   [2, 2, 1, 1, 1, 1, 1, 1],
					   [3, 2, 1, 1, 2, 1, 1, 1],
					   [1, 1, 0, 0, 0, 0, 0, 0],
					   [3, 1, 1, 1, 3, 0, 1, 1],
					   [1, 0, 1, 0, 1, 0, 1, 1],
					   [2, 1, 1, 1, 1, 0, 0, 0]]
	
	var rand_resultant_amount = [[], [], [], [], [], [], [], [], [], [], [], []]
	var rand_resultant_type = [[], [], [], [], [], [], [], [], [], [], [], []]
	var empty_type = 0
	var replacables = []
	var temp_adjacents = []
	var same_count = 0
	var temp_node = null
	
	# for each area type
	for area_type in area_nodes.size():
		# set number of empty nodes to size of area
		empty_type = area_nodes[area_type].size()

		# for each stat node type
		for stat_type in 8:
			# create x stat node type, where x is the base amount + a random weighted flactuation
			rand_resultant_amount[area_type].push_back(area_amount[area_type][stat_type] + round(rand_weight[area_type][stat_type] * (randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25) + randf_range(-0.25, 0.25))))
			empty_type -= rand_resultant_amount[area_type][stat_type] # reduce the number of empty nodes by x
			# assign x variables to texture region based on stat node type
			for rand_number in rand_resultant_amount[area_type][stat_type]:
				rand_resultant_type[area_type].push_back(stats_node_atlas_position[stat_type])
			
		# assign y variables to texture region of empty node type, where y is the remaining unchanged nodes
		for number in empty_type:
			rand_resultant_type[area_type].push_back(empty_node_atlas_position)

		# shuffle area array
		rand_resultant_type[area_type].shuffle()

		for array_index in area_nodes[area_type].size():
			# temp_texture_region = temp_texture.get_region()
			nexus_nodes[area_nodes[area_type][array_index]].texture.region = Rect2(rand_resultant_type[area_type][array_index], Vector2(32, 32))

		replacables.clear()

		for temp_node_index in area_nodes[area_type]:
			# if node is empty
			if nexus_nodes[temp_node_index].texture.region == Rect2(Vector2(0, 0), Vector2(32, 32)):
				# add node to replacables
				replacables.push_back(temp_node_index)

		for i in 5:
			for temp_node_index in area_nodes[area_type]:
				replacables.shuffle()
				temp_adjacents.clear()
				same_count = 0

				# determine adjacent nodes
				if (temp_node_index % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
				else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)

				for adjacent in temp_adjacents: # for each adjacent node
					# if adjacent node exists and has a same type neighbour, add 1 to count
					if (adjacent > -1) && (adjacent < 767) && nexus_nodes[temp_node_index].texture.region == nexus_nodes[adjacent].texture.region:
						same_count += 1

				# if more than 1 same type neighbour
				if same_count > 0:
					# replace an empty node with this node type, and this node becomes empty
					nexus_nodes[replacables.pop_back()].texture.region = nexus_nodes[temp_node_index].texture.region
					nexus_nodes[temp_node_index].texture.region = Rect2(Vector2(0, 0), Vector2(32, 32))

					replacables.push_back(temp_node_index)
			
		replacables.clear()

		for temp_node_index in area_nodes[area_type]:
			temp_adjacents.clear()
			same_count = 0

			print(same_count)

			# if node is empty
			if nexus_nodes[temp_node_index].texture.region != Rect2(Vector2(0, 0), Vector2(32, 32)):
				# determine adjacent nodes
				if (temp_node_index % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
				else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)
				
				for adjacent in temp_adjacents: # for each adjacent node
					# if adjacent node exists and has a same type neighbour, add 1 to count
					if (adjacent > -1) && (adjacent < 767) && nexus_nodes[adjacent].texture.region == Rect2(Vector2(0, 0), Vector2(32, 32)):
						same_count += 1
				
				print(same_count)

				# add node to replacables
				if same_count < 3:
					replacables.push_back(temp_node_index)

		for i in 5:
			for temp_node_index in area_nodes[area_type]:
				replacables.shuffle()
				temp_adjacents.clear()
				same_count = 0

				# determine adjacent nodes
				if (temp_node_index % 32) < 16: for temp_index in adjacents_index[0]: temp_adjacents.push_back(temp_node_index + temp_index)
				else: for temp_index in adjacents_index[1]: temp_adjacents.push_back(temp_node_index + temp_index)

				for adjacent in temp_adjacents: # for each adjacent node
					# if adjacent node exists and has a same type neighbour, add 1 to count
					if (adjacent > -1) && (adjacent < 767) && nexus_nodes[temp_node_index].texture.region == nexus_nodes[adjacent].texture.region:
						same_count += 1

				# if more than 1 same type neighbour
				if same_count > 1:
					# replace a stats node with this node type, and this node becomes a stats node
					temp_node = nexus_nodes[replacables.pop_back()]
					nexus_nodes[temp_node_index].texture.region = temp_node.texture.region
					temp_node.texture.region = Rect2(Vector2(0, 0), Vector2(32, 32))

					replacables.push_back(temp_node_index)
	
	# save randomized textures
	for node in nexus_nodes:
		if node.texture.region.position in stats_node_atlas_position:
			GlobalSettings.nexus_default_atlas_positions.push_back(node.texture.region.position)
		else:
			GlobalSettings.nexus_default_atlas_positions.push_back(Vector2.ZERO)
			
	for node in nexus_nodes:
		if node.texture.region.position == Vector2(32, 0): null_nodes.push_back(node.get_index()) # null
		elif node.texture.region.position.y == 96: # keys
			if node.texture.region.position.x == 0: key_nodes[0].push_back(node.get_index()) # diamond
			elif node.texture.region.position.x == 32: key_nodes[1].push_back(node.get_index()) # clover
			elif node.texture.region.position.x == 64: key_nodes[2].push_back(node.get_index()) # heart
			elif node.texture.region.position.x == 96: key_nodes[3].push_back(node.get_index()) # spade

	for i in 767:
		nodes_quality.push_back(0)

	# save amount
	for area_type in area_nodes.size():
		for node_index in area_nodes[area_type]:
			for i in stats_node_atlas_position.size():
				if nexus_nodes[node_index].texture.region.position == stats_node_atlas_position[i]:
					nodes_quality[node_index] = default_stats_qualities[i][default_area_stats_qualities[area_type][i]][randi() % default_stats_qualities[i][default_area_stats_qualities[area_type][i]].size()]

	# check for all adjacent unlockables
	# for each player in possibly unlocked players
	for player_index in GlobalSettings.unlocked_players.size():
		# if player is unlocked
		if GlobalSettings.unlocked_players[player_index]:
			# for each unlocked node
			for node in nodes_unlocked[player_index]:
				# determine adjacent nodes
				temp_adjacents.clear()
				if (node % 32) < 16:
					for temp_index in adjacents_index[0]: temp_adjacents.push_back(node + temp_index)
				else:
					for temp_index in adjacents_index[1]: temp_adjacents.push_back(node + temp_index)

				# for each adjacent node
				for adjacent in temp_adjacents:
					# if node is not unlocked, is not null, and node exists
					if !(adjacent in nodes_unlocked[player_index]) && !(adjacent in null_nodes) && (adjacent > -1) && (adjacent < 767):
						# determine second adjacent nodes
						var second_temp_adjacents = []
						if (adjacent % 32) < 16:
							for second_temp_index in adjacents_index[0]: second_temp_adjacents.push_back(adjacent + second_temp_index)
						else:
							for second_temp_index in adjacents_index[1]: second_temp_adjacents.push_back(adjacent + second_temp_index)

						# for second adjacent node
						for second_adjacent in second_temp_adjacents:
							# if second adjacent is unlocked, is not original node, and is not in unlockables array
							if (second_adjacent in nodes_unlocked[player_index]) && (second_adjacent != node) && !(adjacent in nodes_unlockable[player_index]):
								nodes_unlockable[player_index].push_back(adjacent)

func update_nexus_player(player):
	current_nexus_player = player

	# disable all textures
	for node in nexus_nodes:
		node.modulate = Color(0.25, 0.25, 0.25, 1)

	# update null node textures
	for node_index in null_nodes:
		nexus_nodes[node_index].modulate = Color(0.2, 0.2, 0.2, 1)

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
		unlockable_instance.name = str(node_index)
		get_node("UnlockableNodes").add_child(unlockable_instance)
		unlockable_instance.position = nexus_nodes[node_index].position
	
	print(nodes_unlockable[current_nexus_player])
	print(get_node("UnlockableNodes").get_children())
	for node in get_node("UnlockableNodes").get_children():
		print(node.position)
	
	nexus_player_node.position = nexus_nodes[last_nodes[current_nexus_player]].position + Vector2(16, 16)
	nexus_player_node.get_node("Sprite2D").show()
	nexus_player_node.get_node("Sprite2D2").hide()

	var i = 0
	for node in nexus_nodes:
		if node.texture.region.position == empty_node_atlas_position:
			i += 1
	print(i)

func unlock_node():
	# if current nexus node is in current player unlockables, and node is not a null node
	if last_nodes[current_nexus_player] in nodes_unlockable[current_nexus_player] && nexus_nodes[last_nodes[current_nexus_player]].texture.region.position != null_node_atlas_position:
		# add node index to unlocked
		nodes_unlocked[current_nexus_player].push_back(last_nodes[current_nexus_player])
		# remove node index from unlockables
		nodes_unlockable[current_nexus_player].erase(last_nodes[current_nexus_player])
		# remove node unlockables outline
		get_node("UnlockableNodes").remove_child(get_node("UnlockableNodes").get_node(str(last_nodes[current_nexus_player])))

		# update unlocked node texture
		nexus_nodes[last_nodes[current_nexus_player]].modulate = Color(1, 1, 1, 1)

		var temp_adjacents = []

		# determine index differences to adjacent nodes
		if (last_nodes[current_nexus_player] % 32) < 16:
			for temp_index in adjacents_index[0]:
				temp_adjacents.push_back(last_nodes[current_nexus_player] + temp_index)
		else:
			for temp_index in adjacents_index[1]:
				temp_adjacents.push_back(last_nodes[current_nexus_player] + temp_index)

		# for each adjacent node
		for adjacent in temp_adjacents:
			# if node is not unlocked and node exists
			if !(adjacent in nodes_unlocked[current_nexus_player]) && nexus_nodes[adjacent].texture.region.position != null_node_atlas_position && (adjacent > -1) && (adjacent < 767):
				var second_temp_adjacents = []
				
				# determine index differences to second adjacent nodes (nodes adjacent to adjacent nodes)
				if (adjacent % 32) < 16:
					for second_temp_index in adjacents_index[0]:
						second_temp_adjacents.push_back(adjacent + second_temp_index)
				else:
					for second_temp_index in adjacents_index[1]:
						second_temp_adjacents.push_back(adjacent + second_temp_index)

				# for each second adjacent nodes
				for second_adjacent in second_temp_adjacents:
					# if second adjacent is unlocked, is not original node, and is not in unlockables array
					if (second_adjacent in nodes_unlocked[current_nexus_player]) && (second_adjacent != last_nodes[current_nexus_player]) && !(adjacent in nodes_unlockable[current_nexus_player]):
						# add adjacent node to unlockables
						nodes_unlockable[current_nexus_player].push_back(adjacent)

						# create unlockables outline for adjacent node
						unlockable_instance = unlockable_load.instantiate()
						unlockable_instance.name = str(adjacent)
						get_node("UnlockableNodes").add_child(unlockable_instance)
						unlockable_instance.position = nexus_nodes[adjacent].position

func exit_nexus():
	GlobalSettings.unlocked_nodes = nodes_unlocked.duplicate()

	# for each unlocked player
	for player_index in 4:
		if GlobalSettings.unlocked_players[player_index]:
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

	GlobalSettings.target_zoom = Vector2(1.0, 1.0)
	GlobalSettings.camera_node.zoom = Vector2(1.0, 1.0)
	GlobalSettings.current_camera_node = GlobalSettings.camera_node
	GlobalSettings.camera_node.reparent(GlobalSettings.current_main_player_node)
	GlobalSettings.camera_node.position = Vector2.ZERO
	queue_free()
