extends Node2D

func initiate_dialogue():
	call_deferred("default_dialogue")

func default_dialogue():
	TextBox.text_owner_node = self
	TextBox.text_queue += ["Never gonna give you up.",
						   "Never gonna let you down.",
						   "Never gonna run around and desert you!"]
	TextBox.text_box_state = TextBox.TextBoxState.READY
