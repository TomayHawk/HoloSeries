extends AnimatedSprite2D

func can_interact() -> bool:
    return TextBox.isInactive() # TODO: add conditions

func interact() -> void:
    toggle_timer()

func toggle_timer() -> void:
    if $Timer.is_stopped():
        $Timer.start()
    else:
        $Timer.stop()

# TODO: don't like this
func _on_timer_timeout():
    var enemy_instance = load("res://entities/enemies/enemy_specifics/nousagi.tscn").instantiate()
    enemy_instance.position = position + Vector2(25 * randf_range(-1, 1), 25 * randf_range(-1, 1))
    Global.tree.current_scene.get_node(^"Enemies").add_child(enemy_instance)
