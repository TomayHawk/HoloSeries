extends AnimatedSprite2D

func can_interact() -> bool:
    return TextBox.isInactive() and not Combat.in_combat()
    
func interact():
    pass # TODO: Display Save UI
