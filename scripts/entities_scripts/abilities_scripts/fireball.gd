extends CharacterBody2D

@onready var animation_node = $AnimatedSprite2D#@onready var fireball_load = preload("res://entities/abilities/fireball.tscn")

@export var damage = 50
@export var speed = 100

func _ready():
	velocity = speed * (Vector2(-1, 0)) #left for now

func _physics_process(_delta):
	move_and_slide()
	$AnimatedSprite2D.play("shoot")


func _on_visible_on_screen_enabler_2d_screen_exited():
	queue_free()


func _on_checker_body_entered(body):
	queue_free()
