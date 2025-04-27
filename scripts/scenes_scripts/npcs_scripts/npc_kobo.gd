extends AnimatedSprite2D

func initiate_dialogue():
	call_deferred(&"default_dialogue")

func default_dialogue():
	TextBox.npcDialogue([
		"Never gonna give you up.",
		"Never gonna let you down.",
		"Never gonna run around and desert you!"
	], [])
