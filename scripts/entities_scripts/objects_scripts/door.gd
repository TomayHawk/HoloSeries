extends Node2D

func interact_conditions_met():
    return (TextBox.text_box_state == TextBox.TextBoxState.INACTIVE and !CombatEntitiesComponent.in_combat)
