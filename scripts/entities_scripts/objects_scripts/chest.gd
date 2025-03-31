extends AnimatedSprite2D

var chest_open: bool = false

func can_interact() -> bool:
    return TextBox.isInactive() and not Combat.in_combat()

# TODO: improve this
func interact() -> void:
    if chest_open:
        $AnimatedSprite2D.pause()
    else:
        $AnimatedSprite2D.play("default")

    chest_open = not chest_open
