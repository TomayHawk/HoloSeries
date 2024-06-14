extends Node2D

var unlocked_players = [true, true, false, false, false, false, false, false, false, false]
var players_modulate = ["", "", "", "", "", "", "", "", "", ""]
var current_node = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

var nodes_index = [[get_node("Control/Skill"), 0, 1, - 1], [get_node("Control/HeartLock"), 1, 0, 2], [], []]
var line_index = []

var default_unlocked = [[], [], [], [], [], [], [], [], [], []]
var all_nodes_unlock_status = [[[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []]]
var all_nodes_unlockable = [[[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []], [[], []]]
var all_line_unlocked = [[], [], [], [], [], [], [], [], [], []]

var node_texture = null
var node_texture_region = null

func _ready():
	for i in 10: if unlocked_players[i] != GlobalSettings.global_unlocked_players[i]
		unlocked_players[i] == GlobalSettings.global_unlocked_players[i]
		add_player_nexus
	all_nodes_unlock_status = GlobalSettings.global_all_nodes_unlocked.duplicate()

	update_nexus_player(GlobalSettings.current_main_player)

func update_nexus_player(player):
	for node in 88: if all_nodes_unlock_status[player][0][node]:
		#
		pass

func unlock_node(player, node_type, current_node, adjacent_unlockable):
	if !all_nodes_unlocked[player][node_type][current_node]:
		all_nodes_unlocked[player][node_type][current_node] = true

		# update node texture
		# update line texture

func update_all_texture(node):
	node_texture = node.texture_normal

	##### currently changing texture, should change modulate value instead
	node_texture_region = node_texture.get_region()
	node.texture_normal.set_region(Rect2(node_texture_region.position + Vector2(32, 0), node_texture_region.size))
