extends AnimatedSprite2D

@export var enemy_path: String = "res://entities/enemies/nousagi.tscn"
@export var spawn_limit: int = 20

func can_interact() -> bool:
    return TextBox.isInactive()

func interact() -> void:
    if $Timer.is_stopped():
        $Timer.start()
    else:
        $Timer.stop()
    
func _on_timer_timeout() -> void:
    if Global.get_tree().get_nodes_in_group(StringName(name)).size() > spawn_limit: return
    var enemy_instance: EnemyBase = Entities.add_enemy_to_scene(load(enemy_path), position, 25.0)
    enemy_instance.add_to_group(StringName(name))
