extends Node2D

func _ready():
	GlobalSettings.update_players()
	PartyStatsComponent.update_players_stats()
	GlobalSettings.players[GlobalSettings.current_main_player].position = GlobalSettings.next_spawn_position

func _on_world_scene_2_transit_body_entered(body):
	if body.current_main:
		GlobalSettings.change_scene(get_node("/root/DungeonScene1/"), "res://scenes/world_scene_2.tscn", 3)
