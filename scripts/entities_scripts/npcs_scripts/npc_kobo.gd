extends Node2D

func default_dialogue():
	TextBox.text_owner_node = self
	TextBox.text_queue += ["Never gonna give you up.",
						   "Never gonna let you down.",
						   "Never gonna run around and desert you!"]
	TextBox.current_state = TextBox.Text.READY
