extends CanvasLayer

func _ready() -> void:
	Global.tree.set_pause(true)
	Inputs.combat_inputs_enabled = false
	Combat.ui.hide()
	TextBox.reset()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"esc"):
		Inputs.accept_event()
		exit_deck()

func _on_characters_pressed() -> void:
	Global.add_global_child("CharactersUi", "res://user_interfaces/holo_deck/characters_ui.tscn")
	queue_free()

func _on_abilities_pressed() -> void:
	Global.add_global_child("AbilitiesUi", "res://user_interfaces/holo_deck/abilities_ui.tscn")
	queue_free()

func _on_holo_nexus_pressed() -> void:
	Global.add_global_child("HoloNexus", "res://user_interfaces/holo_deck/holo_nexus.tscn")
	queue_free()

func _on_inventory_pressed() -> void:
	Global.add_global_child("InventoryUi", "res://user_interfaces/holo_deck/inventory_ui.tscn")
	queue_free()

func _on_settings_pressed() -> void:
	Global.add_global_child("SettingsUi", "res://user_interfaces/settings_ui.tscn")
	queue_free()

func _on_resume_pressed() -> void:
	exit_deck()

func exit_deck():
	Global.tree.set_pause(false)
	Inputs.combat_inputs_enabled = true
	Combat.ui.show()
	queue_free()

func _on_exit_game_pressed() -> void:
	pass # Replace with function body.
