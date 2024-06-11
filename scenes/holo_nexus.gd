extends Node2D

var unlocked_players = [true, true]
var players_modulate = ["", ""]
var current_node = [Vecto2.ZERO, Vecto2.ZERO]

var all_nodes_index = []
var line_nodes_index = []

var all_nexus_nodes = [[[]]]
var all_line_nodes = [[]]

func _ready():
	all_nexus_nodes = GlobalSettings.global_all_nexus_nodes

func update_global_nexus_nodes():
	GlobalSettings.global_all_nexus_nodes = all_nexus_nodes

func unlock_node(player, node_type, current_node):
	if !all_nexus_nodes[player][node_type][current_node]:
		all_nexus_nodes[player][node_type][current_node] = true
