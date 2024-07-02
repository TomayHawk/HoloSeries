extends CanvasLayer

@onready var nexus = get_parent()

func _on_unlock_pressed():
	nexus.unlock_node()
