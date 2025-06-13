extends CanvasLayer

var name_labels: Array[Label] = []
var health_labels: Array[Label] = []
var mana_labels: Array[Label] = []
var ultimate_progress_bars: Array[ProgressBar] = []
var shield_progress_bars: Array[ProgressBar] = []

var standby_name_labels: Array[Label] = []
var standby_level_labels: Array[Label] = []
var standby_health_labels: Array[Label] = []
var standby_mana_labels: Array[Label] = []

var tween: Tween

@onready var sub_modes_nodes: Array[Node] = %SubModesMarginContainer.get_children()
@onready var items_grid_container_node: GridContainer = %ItemsGridContainer

# ..............................................................................

func _ready() -> void:
	%CombatControl.modulate.a = 0.0
	%SubCombatOptions.hide()
	%CharacterSelector.hide()

	var character_infos_nodes: Array[Node] = %CharacterInfosVBoxContainer.get_children()
	for character_infos_node in character_infos_nodes:
		name_labels.push_back(character_infos_node.get_node(^"CharacterName"))
		health_labels.push_back(character_infos_node.get_node(^"HealthAmount"))
		mana_labels.push_back(character_infos_node.get_node(^"ManaAmount"))
		ultimate_progress_bars.push_back(character_infos_node.get_node(^"Ultimate"))
		shield_progress_bars.push_back(character_infos_node.get_node(^"Shield"))

func _input(_event: InputEvent) -> void:
	if not Inputs.combat_inputs_enabled: return
	if Input.is_action_just_pressed(&"display_combat_ui"):
		Inputs.accept_event()
		if Combat.not_in_combat():
			%CombatControl.modulate.a = 1.0 if %CombatControl.modulate.a != 1.0 else 0.0
	elif Input.is_action_just_pressed(&"tab"):
		Inputs.accept_event()
		%CharacterSelector.show()
	elif Input.is_action_just_released(&"tab"):
		Inputs.accept_event()
		%CharacterSelector.hide()
	elif Input.is_action_just_pressed(&"esc"):
		if %SubCombatOptions.visible:
			Inputs.accept_event()
			hide_sub_combat_options()

# ..............................................................................

# UI TWEEN

func combat_ui_tween(target_visibility_value: float) -> void:
	tween = create_tween()
	tween.tween_property(%CombatControl, "modulate:a", target_visibility_value, 0.2)

# ..............................................................................

# MAIN COMBAT OPTIONS

func _on_attack_pressed() -> void:
	hide_sub_combat_options()

func _on_main_combat_options_pressed(extra_arg_0: int) -> void:
	hide_sub_combat_options()
	%SubCombatOptions.show()
	sub_modes_nodes[extra_arg_0].show()

# ..............................................................................

# SUB COMBAT OPTIONS

func instantiate_ability(ability_index: int) -> void:
	Combat.abilities_node.add_child(Combat.ability_loads[ability_index].instantiate())

func use_consumable(item_index: int) -> void:
	Inventory.use_consumable(item_index)

func hide_sub_combat_options() -> void:
	%SubCombatOptions.hide()
	for sub_mode in sub_modes_nodes:
		sub_mode.hide()

# ..............................................................................

# SIGNALS AND BUTTON PRESSES

func _on_control_mouse_entered() -> void:
	Inputs.mouse_in_combat_area = false
	Players.camera_node.can_zoom = false

func _on_control_mouse_exited() -> void:
	Inputs.mouse_in_combat_area = true
	Players.camera_node.can_zoom = true

func button_pressed() -> void:
	Entities.end_entities_request()
