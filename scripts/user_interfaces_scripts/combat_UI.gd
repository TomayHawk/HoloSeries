extends CanvasLayer

# TODO: should seperate CombatUI into multiple scenes

@onready var control_node := %CombatUIControl
@onready var combat_options_2_node := %CombatOptions2
@onready var character_selector_node := %CharacterSelector
@onready var combat_options_2_modes := %Options2Margin.get_children()
@onready var players_info_nodes := %CharacterInfosVBoxContainer.get_children()
@onready var ultimate_progress_bar_nodes := %UltimateProgressBarControl.get_children()
@onready var shield_progress_bar_nodes := %ShieldProgressBarControl.get_children()
@onready var character_selector_player_nodes := %CharacterSelectorVBoxContainer.get_children()

@onready var items_grid_container_node: GridContainer = %ItemsGridContainer

@onready var abilities_load: Array[Resource] = [
	load("res://abilities/fireball.tscn"),
	load("res://abilities/regen.tscn"),
	load("res://abilities/heal.tscn"),
	load("res://abilities/play_dice.tscn"),
	load("res://abilities/rocket_launcher.tscn"),
]

var items_quantities_nodes: Array[Node] = []

var tween

var character_name_label_nodes: Array[Node] = []
var players_health_label_nodes: Array[Node] = []
var players_mana_label_nodes: Array[Node] = []
var character_selector_name_nodes: Array[Node] = []
var character_selector_level_nodes: Array[Node] = []
var character_selector_health_nodes: Array[Node] = []
var character_selector_mana_nodes: Array[Node] = []

# TODO: PLAYER_HIT should not be here
const BASE_ITEM_TYPES: int = \
		Damage.DamageTypes.PLAYER_HIT \
		| Damage.DamageTypes.ITEM \
		| Damage.DamageTypes.NO_CRITICAL \
		| Damage.DamageTypes.NO_RANDOM \
		| Damage.DamageTypes.NO_MISS

const REQUEST_TYPES: Dictionary[String, Array] = {
	"use_potion": [[Entities.Type.PLAYERS_PARTY_ALIVE], 1],
	"use_phoenix_burger": [[Entities.Type.PLAYERS_PARTY_DEAD], 1],
	"use_temp_kill_item": [[Entities.Type.PLAYERS_PARTY_ALIVE], 1],
}

const DAMAGE_TYPES: Dictionary[String, int] = {
	"use_potion": BASE_ITEM_TYPES | Damage.DamageTypes.HEAL,
	"use_max_potion": BASE_ITEM_TYPES | Damage.DamageTypes.HEAL | Damage.DamageTypes.BREAK_LIMIT,
	"use_phoenix_burger": BASE_ITEM_TYPES | Damage.DamageTypes.HEAL | Damage.DamageTypes.BREAK_LIMIT,
	"use_reset_button": BASE_ITEM_TYPES | Damage.DamageTypes.HEAL | Damage.DamageTypes.BREAK_LIMIT | Damage.DamageTypes.HIDDEN,
	"use_temp_kill_item": BASE_ITEM_TYPES | Damage.DamageTypes.COMBAT | Damage.DamageTypes.BREAK_LIMIT | Damage.DamageTypes.HIDDEN,
}

signal entities_chosen

func _ready():
	for i in 4:
		character_name_label_nodes.push_back(players_info_nodes[i].get_node(^"HBoxContainer/CharacterName"))
		players_health_label_nodes.push_back(players_info_nodes[i].get_node(^"HBoxContainer/MarginContainer/HealthAmount"))
		players_mana_label_nodes.push_back(players_info_nodes[i].get_node(^"HBoxContainer/MarginContainer2/ManaAmount"))
		character_selector_name_nodes.push_back(character_selector_player_nodes[i].get_node(^"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/CharacterName"))
		character_selector_level_nodes.push_back(character_selector_player_nodes[i].get_node(^"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Level"))
		character_selector_health_nodes.push_back(character_selector_player_nodes[i].get_node(^"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer/HealthAmount"))
		character_selector_mana_nodes.push_back(character_selector_player_nodes[i].get_node(^"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MarginContainer2/ManaAmount"))

	control_node.modulate = Color.TRANSPARENT
	combat_options_2_node.hide()
	
	character_selector_node.hide()

	for button in character_selector_player_nodes:
		button.hide()
	
	for button in %ItemsGridContainer.get_children():
		items_quantities_nodes.push_back(button.get_node(^"Quantity"))
	
func _input(_event: InputEvent) -> void:
	if not Inputs.combat_inputs_enabled:
		return

	if Input.is_action_just_pressed(&"display_combat_ui"):
		Inputs.accept_event()
		combat_ui_display()
	elif Input.is_action_just_pressed(&"tab"):
		Inputs.accept_event()
		character_selector_node.show()
	elif Input.is_action_just_released(&"tab"):
		Inputs.accept_event()
		character_selector_node.hide()
	elif Input.is_action_just_pressed(&"esc"):
		if combat_options_2_node.is_visible():
			Inputs.accept_event()
			hide_combat_options_2()

# display combat ui
func combat_ui_display():
	if not Combat.in_combat() and get_tree().current_scene.name != "MainMenu":
		if control_node.modulate.a != 1.0:
			control_node.modulate.a = 1.0
		elif not Combat.leaving_combat():
			control_node.modulate.a = 0.0

# CombatUI health text update
func update_health_label(party_index, health):
	players_health_label_nodes[party_index].text = str(floor(health))

func update_mana_label(party_index, mana):
	players_mana_label_nodes[party_index].text = str(floor(mana))

# CombatUI control visibility animation
func combat_ui_tween(target_visibility_value):
	tween = create_tween()
	tween.tween_property(control_node, "modulate:a", target_visibility_value, 0.2)

func update_consumables() -> void:
	var item_count: int = Inventory.consumables_inventory.size()
	for index in item_count:
		if Inventory.consumables_inventory[index] > 0:
			var button_node = Button.new()
			button_node.text = Inventory.consumables_resources[index].new().button_name
			button_node.name = button_node.text.replace(" ", "")
		
		#items_quantities_nodes[item_index].text = str(Inventory.consumables_inventory[item_index])

		#if Inventory.consumables_inventory[item_index] == 0:
		#	items_quantities_nodes[item_index].get_parent().hide()

func update_character_selector():
	for button in character_selector_player_nodes:
		button.hide()

	var i = 0 # TODO: need to add character selector options as a resource
	for character_node in Players.standby_node.get_children():
		character_selector_player_nodes[i].show()
		character_selector_name_nodes[i].text = character_node.character_name
		character_selector_level_nodes[i].text = "Lvl " + str(character_node.level).pad_zeros(3)
		character_selector_health_nodes[i].text = str(floor(character_node.health))
		character_selector_mana_nodes[i].text = str(floor(character_node.mana))
		i += 1

func button_pressed():
	Entities.reset_entity_request()

# CombatOptions1 (Basic Attack)
func _on_attack_pressed():
	hide_combat_options_2()

# CombatOptions1
func _on_combat_options_1_pressed(extra_arg_0):
	hide_combat_options_2()
	if combat_options_2_node.visible and combat_options_2_modes[extra_arg_0].visible:
		return
	else:
		combat_options_2_node.show()
		combat_options_2_modes[extra_arg_0].show()

func hide_combat_options_2():
	combat_options_2_node.hide()
	for mode in combat_options_2_modes:
		mode.hide()

# CombatOptions2	

#0: Fireball
#1: Regen
#2: Heal
#3: Play Dice

# create ability nodes
func instantiate_ability(ability_index):
	# create and add ability instance to abilities node
	Combat.abilities_node.add_child(abilities_load[ability_index].instantiate())

func use_item(extra_arg_0):
	if Inventory.consumables_inventory[extra_arg_0] == 0:
		items_quantities_nodes[extra_arg_0].get_parent().hide()
		return false

	Inventory.consumables_inventory[extra_arg_0] -= 1
	items_quantities_nodes[extra_arg_0].text = str(Inventory.consumables_inventory[extra_arg_0])
	return true

# TODO: TEMP VARIABLE
var last_item_string = ""

# request entities for items (target_command, request_count)
func request_entities(extra_arg_0):
	last_item_string = extra_arg_0
	connect("entities_chosen", Callable(self, extra_arg_0))
	# TODO: temporary code
	var entity_types: Array[Entities.Type] = []
	if extra_arg_0 == "use_potion":
		entity_types = [Entities.Type.PLAYERS_PARTY_ALIVE]
	elif extra_arg_0 == "use_phoenix_burger":
		entity_types = [Entities.Type.PLAYERS_PARTY_DEAD]
	elif extra_arg_0 == "use_temp_kill_item":
		entity_types = [Entities.Type.PLAYERS_PARTY_ALIVE]
	Entities.request_entities(self, entity_types, REQUEST_TYPES[extra_arg_0][1])

# TODO: add caster information around

# use items
func use_potion(chosen_player_node):
	if not use_item(0): return
	Damage.combat_damage(200.0, DAMAGE_TYPES["use_potion"], chosen_player_node.character_node, chosen_player_node.character_node)
	disconnect("entities_chosen", Callable(self, last_item_string))

func use_max_potion():
	for player in Players.party_node.get_children():
		if player.character_node.alive:
			Damage.combat_damage(99999.0, DAMAGE_TYPES["use_max_potion"], player.character_node, player.character_node)

func use_phoenix_burger(chosen_player_node):
	if not use_item(2): return
	chosen_player_node.character_node.revive()
	Damage.combat_damage(chosen_player_node.character_node.max_health * 0.25, DAMAGE_TYPES["use_phoenix_burger"], chosen_player_node.character_node, chosen_player_node.character_node)
	disconnect("entities_chosen", Callable(self, last_item_string))

func use_reset_button():
	for player in Players.party_node.get_children():
		if not player.character_node.alive:
			player.character_node.revive()
			Damage.combat_damage(player.character_node.max_health, DAMAGE_TYPES["use_reset_button"], player.character_node, player.character_node)

func use_temp_kill_item(chosen_player_node):
	if not use_item(4): return
	Damage.combat_damage(99999, DAMAGE_TYPES["use_temp_kill_item"], chosen_player_node.character_node, chosen_player_node.character_node)
	disconnect("entities_chosen", Callable(self, last_item_string))

func _on_control_mouse_entered():
	Inputs.mouse_in_attack_position = false
	Players.camera_node.can_zoom = false

func _on_control_mouse_exited():
	Inputs.mouse_in_attack_position = true
	Players.camera_node.can_zoom = true

func _on_character_selector_button_pressed(extra_arg_0) -> void:
	Players.update_standby_player(Players.main_player_node.character_node, Players.standby_node.get_child(extra_arg_0))
	update_character_selector()
