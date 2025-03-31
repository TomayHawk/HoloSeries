extends Node

var main_player_node: Node = null

@onready var party_node: Node = $Party
@onready var standby_node: Node = $Standby
@onready var camera_node: Camera2D = $Camera2D

func update_main_player(player_node: Node) -> void:
	main_player_node.is_main_player = false
	player_node.is_main_player = true
	
	main_player_node = player_node
	camera_node.new_parent(player_node)
	Entities.reset_entity_request()

func update_standby_player(player_node: CharacterBody2D, next_character_node: AnimatedSprite2D) -> void:
	next_character_node.party_index = player_node.character_node.party_index
	
	player_node.character_node.reparent(Players.standby_node)
	player_node.character_node.update_nodes()
	player_node.character_node.update_stats()

	next_character_node.reparent(player_node)
	next_character_node.update_nodes()
	next_character_node.update_stats()

	Combat.ui.character_name_label_nodes[next_character_node.party_index].text = next_character_node.character_name
