extends Node2D

var chest_open := false

func interact_conditions_met():
    return (TextBox.text_box_state == TextBox.TextBoxState.INACTIVE and !CombatEntitiesComponent.in_combat)

func interact_object():
    if chest_open:
        $AnimatedSprite2D.pause()
    else:
        $AnimatedSprite2D.play("default")

    chest_open = !chest_open
