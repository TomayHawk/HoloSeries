extends Node2D

@onready var current_nexus_player = GlobalSettings.current_main_player

##### temporary colors
var players_modulate = [Color.BROWN, Color.PEACH_PUFF, Color.PAPAYA_WHIP, Color.PERU]
var recent_node = [0, 0, 0, 0]

var nexus_nodes = []
# [player][node]
var nodes_unlocked = [[9, 10, 11, 12, 13], [0, 5], [], [], [], [], [], [], [], []]
var nodes_unlockable = [[4, 5, 6, 14, 17, 18], [8], [], [], [], [], [], [], [], []]

var recent_emitter = null
var recent_emitter_index = -1

func _ready():
	nodes_unlocked = GlobalSettings.global_unlocked_nodes.duplicate()

	# check for all adjacent unlockables
	for player in 4:
		if GlobalSettings.global_unlocked_players[player]:
			for node_index in nodes_unlocked[player]:
				var temp_adjacents = [node_index - 8, node_index - 4, node_index - 3, node_index + 4, node_index + 5, node_index + 8]
				for temp_index in temp_adjacents:
					if !(temp_index in nodes_unlocked[player])&&temp_index > - 1: # check each adjacent node if not unlocked
						var second_temp_adjacents = [temp_index - 8, temp_index - 4, temp_index - 3, temp_index + 4, temp_index + 5, temp_index + 8]
						# if at least 2 adjacent nodes to that adjacent node is unlocked, the node is unlockable
						for second_temp_index in second_temp_adjacents:
							if (second_temp_index in nodes_unlocked[player])&&second_temp_index != node_index:
								# add adjacent node to unlockable if not already in unlockable
								if !(temp_index in nodes_unlockable[player]):
									nodes_unlockable[player].push_back(temp_index)

	# connect all button signals
	if nexus_nodes.size() == 0: for button in $NexusNodes.get_children():
		nexus_nodes.push_back(button)
	
	update_nexus_player(current_nexus_player)

	##### teleport to $NexusNodes.get_child(recent_node[player])

func update_nexus_player(player):
	current_nexus_player = player

	# disable all textures
	for node in nexus_nodes:
		node.modulate = Color(0.25, 0.25, 0.25, 1)

	# update unlocked textures
	for node_index in nodes_unlocked[current_nexus_player]:
		nexus_nodes[node_index].modulate = Color(1, 1, 1, 1)

	# update unlockable textures
	##### need outline

func unlock_node(node):
	if !(node in nodes_unlocked[current_nexus_player]):
		nodes_unlocked[current_nexus_player].push_back(node)
		nexus_nodes[node].modulate = Color(1, 1, 1, 1)

func exit_nexus():
	GlobalSettings.global_unlocked_nodes = nodes_unlocked.duplicate()

	##### scene change

func _on_nexus_node_pressed(button):
	recent_emitter = button
	recent_emitter_index = button.get_index()
	if button != recent_node[current_nexus_player]||!$NexusPlayer.on_node: $NexusPlayer.snap_to_pressed(recent_emitter)
