extends CanvasLayer

func _ready() -> void:
	Global.get_tree().set_pause(true)
	Inputs.world_inputs_enabled = false
	Combat.ui.hide()
	TextBox.reset()

func _input(event: InputEvent) -> void:
	# ignore all unrelated inputs
	if not event.is_action(&"esc"):
		return
	
	Inputs.accept_event()

	if Input.is_action_just_pressed(&"esc"):
		_on_resume_pressed()

func _on_characters_pressed() -> void:
	Global.add_global_child("CharactersUi", "res://user_interfaces/characters_ui.tscn")
	queue_free()

func _on_abilities_pressed() -> void:
	Global.add_global_child("AbilitiesUi", "res://user_interfaces/abilities_ui.tscn")
	queue_free()

func _on_holo_nexus_pressed() -> void:
	Global.add_global_child("HoloNexus", "res://user_interfaces/holo_nexus.tscn")
	queue_free()

func _on_inventory_pressed() -> void:
	Global.add_global_child("InventoryUi", "res://user_interfaces/inventory_ui.tscn")
	queue_free()

func _on_settings_pressed() -> void:
	Global.add_global_child("SettingsUi", "res://user_interfaces/settings_ui.tscn")
	queue_free()

func _on_resume_pressed() -> void:
	Global.get_tree().set_pause(false)
	Inputs.world_inputs_enabled = true
	Combat.ui.show()
	queue_free()

func _on_exit_game_pressed() -> void:
	pass # Replace with function body.
