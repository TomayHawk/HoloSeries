extends CanvasLayer

func _on_escape_pressed():
    if !GlobalSettings.in_combat:
        get_tree().paused = true
        GlobalSettings.game_paused = true
        GlobalSettings.in_settings = true