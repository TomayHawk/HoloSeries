extends Node2D

var unlocked_players = [true, true, true, true, true, true, true, true, true, true]
var players_modulate = ["", "", "", "", "", "", "", "", "", ""]
var current_node = [Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO, Vecto2.ZERO]

var nodes_index = []
var line_index = []

var default_unlocked = [[], [], [], [], [], [], [], [], [], []]
var all_nodes_unlocked = [[[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []]]
var all_line_unlocked = [[], [], [], [], [], [], [], [], [], []]

func _ready():
    for i in unlocked_players: if i != GlobalSettings.global_unlocked_players:
        i = GlobalSettings.global_unlocked_players

	all_nexus_nodes = GlobalSettings.global_all_nexus_nodes

	for player in unlocked_players: if unlocked_players:
        for node in 88: if all_nexus_nodes[player][0][]
            update_nodes_texture(player, node)
        for node in 888:
            update_nodes_texture(player, node)

func update_global_nexus_nodes():
	GlobalSettings.global_all_nexus_nodes = all_nexus_nodes

func add_player_nexus(player):
    for i in 88: all_nodes_unlocked[][][]
    for i in 888: all_nodes_unlocked[][][]

func unlock_node(player, node_type, current_node):
	if !all_nodes_unlocked[player][node_type][current_node]:
		all_nodes_unlocked[player][node_type][current_node] = true

func update_nodes_texture():
	pass