extends AnimatedSprite2D

func can_interact() -> bool:
	return TextBox.isInactive() and Combat.not_in_combat()
	
func interact():
	pass # TODO: Display Save UI
