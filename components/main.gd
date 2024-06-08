extends Node2D

@onready var main = get_tree().get_root().get_node("main")
@onready var projectile = load("res://projectile.tscn")

func _ready():
    pass

func _physics_process(delta):
    rotation_degrees += 50 * delta

func shoot():
    var instance = projectile.instantiate()
    instance.spawn_direction = rotation
    instance.spawn = position
    instance.spawn_rotation = rotation
    main.add_child.call_deferred(instance)

func _on_cooldown_timeout():
    shoot()