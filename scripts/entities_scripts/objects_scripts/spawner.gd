extends Node2D

@onready var enemies_node := GlobalSettings.tree.current_scene.get_node("Enemies")
@onready var enemy_load := load("res://entities/enemies/enemy_specifics/nousagi.tscn")

var player_can_interact := true

func toggle_timer(initiate):
    if initiate:
        $Timer.start()
    else:
        $Timer.stop()

func interact_object():
    if player_can_interact:
        toggle_timer(!$Timer.paused)

func _on_timer_timeout():
    var enemy_instance = enemy_load.instantiate()
    enemy_instance.position = position + Vector2(25 * randf_range(-1, 1), 25 * randf_range(-1, 1))
    enemies_node.add_child(enemy_instance)
