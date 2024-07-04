extends CanvasLayer

@onready var nexus_node = get_parent()

func _on_unlock_pressed():
	nexus_node.unlock_node()
