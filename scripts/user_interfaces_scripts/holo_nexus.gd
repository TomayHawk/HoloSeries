extends Node2D

@onready var current_nexus_player = GlobalSettings.current_main_player

var unlocked_players = [true, true, false, false, false, false, false, false, false, false]
##### temporary colors
var players_modulate = [Color.BROWN, Color.PEACH_PUFF, Color.PAPAYA_WHIP, Color.PERU, "", "", "", "", "", ""]
var current_node = [null, null, null, null, null, null, null, null, null, null]

# index show individual nodes, and adjacent node index. negative adjacent index represent skill-type index.
# skill_nodes_index[0] is null because of their "negative" index representation
var skill_nodes_index = [null, [get_node("Control/Skill"), 1, - 1], [get_node("Control/HeartLock"), 0, 2], [], []]
var stats_nodes_index = [[get_node("HP"), 7, - 9], [get_node("Defence"), 8, 10], [], []]
# hexagon system
skill_nodes_index = [null, [get_node("SkillNodes/Lightning"), 1, - 1], [get_node("Control/HeartLock"), 0, 2], [], []]
# counter-clockwise from the right
stats_nodes_index = [[get_node("StatNodes/0"), 0, 0, 0, 0, 0, 0], [get_node("StatNodes/1"), 0, 0, 0, 0, 0, 0], [get_node("StatNodes/2"), 0, 0, 0, 0, 0, 0], []]

skill_nodes_adjacent = [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]]
stats_nodes_adjacent = [[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0],[0, 0, 0, 0, 0, 0]]

# line index
var line_index = [[get_node("BigCircle2/Quadrant1/StraightNormal3"), 0, 1], [get_node("BigCircle2/Quadrant1/CurveInnerExtendedLeft"), 1, 2]]

var line_status = [false, false, false, false, false, false, false, false, false, false]

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
	# copy global skills/stats
	skills_unlock_status = GlobalSettings.global_unlocked_skills.duplicate()
	stats_unlock_status = GlobalSettings.global_unlocked_stats.duplicate()

	# create arrays for newly unlocked players
	for player in 10: if unlocked_players[player] != GlobalSettings.global_unlocked_players[player]:
		unlocked_players[player] = GlobalSettings.global_unlocked_players[player]

		# create empty player data
		for nodes in 88: skills_unlock_status[player].push_back(false)
		for nodes in 888: stats_unlock_status[player].push_back(false)

		# update default unlocked nodes
		for node in skills_default_unlocked[player]: skills_unlock_status[player][node] = true
		for node in stats_default_unlocked[player]: stats_unlock_status[player][node] = true

	# display current player nexus
	update_nexus_player(current_nexus_player)

func update_nexus_player(player):
	current_nexus_player = player

	for node in 88:
		node_texture = skill_nodes_index[node][0].texture_normal
		if skills_unlock_status[player][node]:skill_nodes_index[node][0].darkened(0.0)
		else: skill_nodes_index[node][0].darkened(0.85)
	for node in 888:
		node_texture = stats_nodes_index[node][0].texture_normal
		if stats_unlock_status[player][node]:stats_nodes_index[node][0].darkened(0.0)
		else: stats_nodes_index[node][0].darkened(0.85)

	for node in skill_nodes_index:
		pass
		##### if [node[1]]

func unlock_node(node_type, node):
	if node_type == 0:
		if !skills_unlock_status[current_nexus_player][node]:
			skills_unlock_status[current_nexus_player][node] = true
			skill_nodes_index[node][0].modulate = Color(255, 255, 255, 255)
	else:
		if !stats_unlock_status[current_nexus_player][node]:
			stats_unlock_status[current_nexus_player][node] = true
			skill_nodes_index[node][0].modulate = Color(255, 255, 255, 255)

	for adjacent_node in skill_nodes_index[node]:
		if typeof(adjacent_node) == TYPE_INT:

			##### can optimize
			if node < adjacent_node:
				for line in line_index:
					if line[1] == node&&line[2] == adjacent_node:
						line[0].modulate = Color(255, 255, 255, 255)
						line[0].modulate = players_modulate[current_nexus_player]
						break
			else:
				for line in line_index:
					if line[1] == adjacent_node&&line[2] == node:
						line[0].modulate = Color(255, 255, 255, 255)
						line[0].modulate = players_modulate[current_nexus_player]
						break

func on_node(node):
	##### display canvaslayer
	pass

func exit_nexus():
	GlobalSettings.global_unlocked_skills = skills_unlock_status.duplicate()
	GlobalSettings.global_unlocked_stats = stats_unlock_status.duplicate()

	##### scene change
