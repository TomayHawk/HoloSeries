extends Node

var main_player_node: Node = null

@onready var party_node: Node2D = $Party
@onready var standby_node: Node = $Standby
@onready var camera_node: Camera2D = $Camera2D

func update_main_player(player_node: PlayerBase) -> void:
	main_player_node.is_main_player = false
	player_node.is_main_player = true
	
	main_player_node = player_node
	camera_node.new_parent(player_node)
	Entities.end_entities_request()

func update_standby_player(standby_index: int) -> void:
	var prev_character: PlayerStats = main_player_node.character
	var next_character: PlayerStats = standby_node.get_child(standby_index)
	
	var party_index: int = prev_character.node_index
	prev_character.node_index = standby_index
	next_character.node_index = party_index
	
	prev_character.reparent(standby_node)
	standby_node.move_child(prev_character, standby_index)

	next_character.reparent(main_player_node)

	prev_character.update_nodes()
	next_character.update_nodes()
