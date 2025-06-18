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

# READY

func _ready() -> void:
	%CombatControl.modulate.a = 0.0
	%SubCombatOptions.hide()
	%CharacterSelector.hide()

	var character_infos_nodes: Array[Node] = %CharacterInfosVBoxContainer.get_children()
	for character_infos_node in character_infos_nodes:
		name_labels.append(character_infos_node.get_node(^"CharacterName"))
		health_labels.append(character_infos_node.get_node(^"HealthAmount"))
		mana_labels.append(character_infos_node.get_node(^"ManaAmount"))
		ultimate_progress_bars.append(character_infos_node.get_node(^"Ultimate"))
		shield_progress_bars.append(character_infos_node.get_node(^"Shield"))

# INPUT

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

# ADD BUTTONS

func add_items() -> void:
	var index: int = 0
	var options_button_load: PackedScene = \
			load("res://user_interfaces/user_interfaces_resources/combat_ui/options_button.tscn")

	for count in Inventory.consumables_inventory:
		if count > 0:
			var options_button: Button = options_button_load.instantiate()
			var item_name: String = Inventory.consumables[index].new().item_name
			options_button.name = item_name
			options_button.get_node(^"Name").text = item_name
			options_button.get_node(^"Number").text = str(count)
			options_button.pressed.connect(button_pressed)
			options_button.pressed.connect(use_consumable.bind(index))
			options_button.mouse_entered.connect(_on_control_mouse_entered)
			options_button.mouse_exited.connect(_on_control_mouse_exited)
			items_grid_container_node.add_child(options_button)
		index += 1

func add_standby_character(character: PlayerStats) -> void:
	var standby_button: Button = load("res://user_interfaces/user_interfaces_resources/combat_ui/character_button.tscn").instantiate()
	%CharacterSelectorVBoxContainer.add_child(standby_button)

	# set button labels
	standby_button.get_node(^"Name").text = character.CHARACTER_NAME
	standby_button.get_node(^"Level").text = str(character.level)
	standby_button.get_node(^"HealthAmount").text = str(int(character.health))
	standby_button.get_node(^"ManaAmount").text = str(int(character.mana))

	# set button signals and connections
	standby_button.pressed.connect(Players.update_standby_player.bind(standby_button.get_index()))
	standby_button.pressed.connect(button_pressed)
	standby_button.mouse_entered.connect(_on_control_mouse_entered)
	standby_button.mouse_exited.connect(_on_control_mouse_exited)
	
	# add button to standby arrays
	standby_name_labels.append(standby_button.get_node(^"Name"))
	standby_level_labels.append(standby_button.get_node(^"Level"))
	standby_health_labels.append(standby_button.get_node(^"HealthAmount"))
	standby_mana_labels.append(standby_button.get_node(^"ManaAmount"))

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
