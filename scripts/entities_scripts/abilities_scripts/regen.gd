extends Node2D
@export var regen_time = 2.0
@export var regen_time_gap = 0.5
@export var heal_percentage = 0.2 

var heal_amount

var total_healed
var regen_timer

var current_player
var player_max_health

var regen_per_tick

# Called when the node enters the scene tree for the first time.
func _ready():
	regen_timer = $Timer
	regen_timer.wait_time = regen_time_gap
	
	current_player = GlobalSettings.current_main_player
	player_max_health = PartyStatsComponent.max_health[GlobalSettings.current_main_player]
	
	heal_amount = player_max_health * heal_percentage
	total_healed = 0
	regen_per_tick = heal_amount * regen_time_gap / regen_time

	regen_timer.start()
	set_process(true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if total_healed >= heal_amount:
		regen_timer.stop()
		print("timer stopped")
		queue_free()
		

func _on_timer_timeout():
	total_healed += regen_per_tick
	PartyStatsComponent.health[current_player] += regen_per_tick
	if PartyStatsComponent.health[current_player] > player_max_health:
		PartyStatsComponent.health[current_player] = player_max_health
		queue_free()
