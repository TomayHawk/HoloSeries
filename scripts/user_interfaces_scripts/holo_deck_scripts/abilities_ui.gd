extends CanvasLayer

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed(&"esc"):
        Inputs.accept_event()
        exit_ui()

func exit_ui() -> void:
    Global.add_global_child("HoloDeck", "res://user_interfaces/holo_deck.tscn")
    queue_free()
