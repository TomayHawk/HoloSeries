extends CanvasLayer

@onready var nexus = get_parent()

func _on_unlock_pressed():
	print("ayo")
	nexus.unlock_node()
