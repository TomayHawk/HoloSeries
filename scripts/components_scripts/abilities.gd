extends Node2D

var current_choosing_ability_node = null
var choosing_player = false
var choosing_enemy = false

func request_player(ability_node):
    choosing_player = true
    current_choosing_ability_node = ability_node

func request_enemy(ability_node):
    choosing_enemy = true
    current_choosing_ability_node = ability_node

func choose_player(chosen_player_node):
    choosing_player = false
    current_choosing_ability_node.update_nodes(chosen_player_node)

func choose_enemy(chosen_enemy_node):
    choosing_enemy = false
    current_choosing_ability_node.update_nodes(chosen_enemy_node)