extends Node

enum CombatState {
	NOT_IN_COMBAT,
	IN_COMBAT,
	LEAVING_COMBAT,
}

const EnemyMarker: PackedScene = preload("res://entities/entities_indicators/enemy_marker.tscn")

var ability_loads: Array[Resource] = [
	load("res://abilities/black_magic/fireball.tscn"),
	load("res://abilities/white_magic/regen.tscn"),
	load("res://abilities/white_magic/heal.tscn"),
	load("res://abilities/skill/play_dice.tscn"),
	load("res://abilities/special/rocket_launcher.tscn"),
]

var enemy_nodes_in_combat: Array[Node] = []
var locked_enemy_node: Node = null

@onready var ui: Node = $CombatUi
@onready var abilities_node: Node = $Abilities
@onready var lootable_items_node: Node = $LootableItems

var combat_state := CombatState.NOT_IN_COMBAT:
	set(next_state):
		if combat_state == next_state: return
		
		match next_state:
			CombatState.NOT_IN_COMBAT:
				ui.combat_ui_tween(0.0)
				$LeavingCombatTimer.stop()
				enemy_nodes_in_combat.clear()
				unlock()
			CombatState.IN_COMBAT:
				if combat_state != CombatState.LEAVING_COMBAT:
					ui.combat_ui_tween(1.0)
				else:
					$LeavingCombatTimer.stop()
			CombatState.LEAVING_COMBAT:
				if combat_state == CombatState.IN_COMBAT:
					$LeavingCombatTimer.start(2)
	
		combat_state = next_state

# check if in combat
func in_combat() -> bool:
	return combat_state == CombatState.IN_COMBAT

# check if leaving combat
func leaving_combat() -> bool:
	return combat_state == CombatState.LEAVING_COMBAT

# check if not in combat
func not_in_combat() -> bool:
	return combat_state == CombatState.NOT_IN_COMBAT

# leave combat
func leave_combat() -> void:
	combat_state = CombatState.NOT_IN_COMBAT

# add enemy to combat
func add_active_enemy(enemy_node: Node) -> void:
	if not enemy_nodes_in_combat.has(enemy_node):
		enemy_nodes_in_combat.append(enemy_node)
	combat_state = CombatState.IN_COMBAT

# remove enemy from combat
func remove_active_enemy(enemy_node: Node) -> void:
	enemy_nodes_in_combat.erase(enemy_node)
	if locked_enemy_node == enemy_node:
		unlock()
	if enemy_nodes_in_combat.is_empty():
		combat_state = CombatState.LEAVING_COMBAT

# lock enemy
func lock(enemy_node: Node) -> void:
	if locked_enemy_node == enemy_node: return
	unlock()
	locked_enemy_node = enemy_node
	var marker_node: Sprite2D = EnemyMarker.instantiate()
	enemy_node.add_child(marker_node)
	marker_node.position = Vector2(0, -40) # should be dynamic

# unlock enemy
func unlock() -> void:
	if locked_enemy_node == null: return
	if locked_enemy_node.has_node(^"EnemyMarker"):
		locked_enemy_node.get_node(^"EnemyMarker").queue_free()
	locked_enemy_node = null

# if node is null, checks if anything is locked
# if node is not null, checks if node is locked
func is_locked(node: Node = null) -> bool:
	return locked_enemy_node == node if node else locked_enemy_node != null

# freeing ability nodes, pick up item nodes, and/or damage display nodes
func clear_combat_entities(abilities: bool = true, lootable_items: bool = true, damage_display: bool = true):
	if abilities:
		for node in abilities_node.get_children():
			node.queue_free()
	if lootable_items: # TODO: should be somewhere else
		for node in lootable_items_node.get_children():
			node.queue_free()
	if damage_display:
		Damage.clear_damage_display()

# LEAVING_COMBAT -> NOT_IN_COMBAT
func _on_leaving_combat_timer_timeout() -> void:
	leave_combat()
