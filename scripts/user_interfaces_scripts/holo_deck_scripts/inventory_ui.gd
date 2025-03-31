extends CanvasLayer

func _ready():
    pass
    # for item_index in miscellaneous_buttons

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed(&"esc"):
        Inputs.accept_event()
        exit_ui()

func update_inventory(_inventory_index):
    pass

func exit_ui() -> void:
    Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
    queue_free()

func _on_inventory_type_button_pressed(_extra_arg_0):
    pass
