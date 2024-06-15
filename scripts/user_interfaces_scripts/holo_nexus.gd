extends Node2D

@onready var current_nexus_player = GlobalSettings.current_main_player

var unlocked_players = [true, true, false, false, false, false, false, false, false, false]
var players_modulate = ["", "", "", "", "", "", "", "", "", ""]
var current_node = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

var nodes_index = [[get_node("Control/Skill"), 0, 1, - 1], [get_node("Control/HeartLock"), 1, 0, 2], [], []]
var line_index = []

# new_player[player][node]
var skills_default_unlocked = [[00, 03, 05], [], [], [], [], [], [], [], [], []]
var stats_default_unlocked = [[000, 003, 005], [], [], [], [], [], [], [], [], []]

# current_players[player][node]
var skills_unlock_status = [[], [], [], [], [], [], [], [], [], []]
var stats_unlock_status = [[], [], [], [], [], [], [], [], [], []]
var skills_unlockable = [[], [], [], [], [], [], [], [], [], []]
var stats_unlockable = [[], [], [], [], [], [], [], [], [], []]

# all_lines_unlocked[player][node]
var all_lines_unlocked = [[], [], [], [], [], [], [], [], [], []]

var node_texture = null
var node_texture_region = null

func _ready():
	# create arrays for newly unlocked players
	for player in 10: if unlocked_players[player] != GlobalSettings.global_unlocked_players[player]:
		unlocked_players[player] = GlobalSettings.global_unlocked_players[player]

		# create empty player data
		for nodes in 88: skills_unlock_status[player].push_back(false)
		for nodes in 888: stats_unlock_status[player].push_back(false)

		# update default unlocked nodes
		for node in skills_default_unlocked[player]: skills_unlock_status[player][node] = true
		for node in stats_default_unlocked[player]: stats_unlock_status[player][node] = true

	skills_unlock_status = GlobalSettings.global_unlocked_skills.duplicate()
	stats_unlock_status = GlobalSettings.global_unlocked_stats.duplicate()

	update_nexus_player(current_nexus_player)

func update_nexus_player(player):
	current_nexus_player = player

	for node in 88:
		if skills_default_unlocked[player][node]: pass # #### modulate
		else: pass # #### modulate
	for node in 888:
		if stats_default_unlocked[player][node]: pass # #### modulate
		else: pass # #### modulate

func unlock_node(node_type, node, adjacent_unlockable):
	if node_type == 0:
		if !skills_unlock_status[current_nexus_player][node]:
			skills_unlock_status[current_nexus_player][node] = true
	else:
		if !stats_unlock_status[current_nexus_player][node]:
			stats_unlock_status[current_nexus_player][node] = true
	
		# update node texture
		# update line texture

func update_all_texture(node):
	node_texture = node.texture_normal

	##### currently changing texture, should change modulate value instead
	node_texture_region = node_texture.get_region()
	node.texture_normal.set_region(Rect2(node_texture_region.position + Vector2(32, 0), node_texture_region.size))
