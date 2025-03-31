extends RigidBody2D

var item_type: int = -1
var item_id: int = -1
var attraction := 1000
var can_leave_attraction := false

var player_nodes: Array[Node] = [] # TODO: use groups instead
var player_in_range := false

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	# TODO: need to change?
	apply_central_impulse(distance_least() * delta)
	if get_colliding_bodies().size() != 0: loot()

func instantiate_item(texture_path, area_scale, id, attraction_strength, item_can_leave_attraction):
	%Sprite2D.texture = load(texture_path)
	%PickUpAreaShape.scale = area_scale
	
	item_id = id
	attraction = attraction_strength
	can_leave_attraction = item_can_leave_attraction

func distance_least():
	var temp_player_node: Node = null
	var temp_distance := INF
	
	for player_node in player_nodes:
		if position.distance_to(player_node.position) < temp_distance:
			temp_player_node = player_node
			temp_distance = position.distance_to(player_node.position)
	
	return (temp_player_node.position - position).normalized() * attraction

func loot():
	match item_type:
		0:
			Inventory.consumables_inventory[item_id] += 1
		1:
			Inventory.materials_inventory[item_id] += 1
		2:
			Inventory.weapons_inventory[item_id] += 1
		3:
			Inventory.armors_inventory[item_id] += 1
		4:
			Inventory.accessories_inventory[item_id] += 1
		5:
			Inventory.nexus_inventory[item_id] += 1
		6:
			Inventory.key_inventory[item_id] += 1
		_:
			pass

	# orb script
	get_colliding_bodies()[0].character_node.update_ultimate_gauge(10)
	get_colliding_bodies()[0].character_node.update_shield(10)
	queue_free()

func _on_area_2d_body_entered(body):
	if not player_nodes.has(body):
		player_nodes.push_back(body)

	player_in_range = true
	set_physics_process(true)

func _on_area_2d_body_exited(body):
	if not can_leave_attraction: return

	player_nodes.erase(body)

	if player_nodes.is_empty():
		player_in_range = false
		set_physics_process(false)
