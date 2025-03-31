extends Node

enum DamageTypes {
	PLAYER_HIT = 0,
	ENEMY_HIT = 1 << 0,
	COMBAT = 1 << 1,
	HEAL = 1 << 2,
	PHYSICAL = 1 << 3,
	MAGIC = 1 << 4,
	ITEM = 1 << 5,
	CRITICAL = 1 << 6,
	NO_CRITICAL = 1 << 7,
	NO_RANDOM = 1 << 8,
	BREAK_LIMIT = 1 << 9,
	MISS = 1 << 10,
	NO_MISS = 1 << 11,
	HIDDEN = 1 << 12,
}

func combat_damage(damage: float, types: int, origin_stats_node: Node, target_stats_node: Node) -> float:
	# TODO: base calculation (very bad code, need fix)
	if types & DamageTypes.COMBAT:
		if types & DamageTypes.PHYSICAL: # physical damage
			damage += (origin_stats_node.strength * 2) + (damage * origin_stats_node.strength * 0.05)
			damage *= origin_stats_node.level / (target_stats_node.level + (origin_stats_node.level * (1 + (target_stats_node.defense * 1.0 / 1500))))
		elif types & DamageTypes.MAGIC: # magic damage
			damage += (origin_stats_node.intelligence * 2) + (damage * origin_stats_node.intelligence * 0.05)
			damage *= origin_stats_node.level / (target_stats_node.level + (origin_stats_node.level * (1 + (target_stats_node.ward * 1.0 / 1500))))
		if types & DamageTypes.PLAYER_HIT and not types & DamageTypes.ITEM: # TODO: don't know why this is here
			damage += (damage * (0.7 - (((target_stats_node.defense - 1000) * (target_stats_node.defense - 1000)) * 1.0 / 1425000))) + (target_stats_node.defense * 1.0 / 3)
		damage *= -1
	elif types & DamageTypes.MAGIC: # magic heal
		damage *= 1 + (origin_stats_node.intelligence * 0.05)

	# attempt crit
	if not types & DamageTypes.NO_CRITICAL and randf() < origin_stats_node.crit_chance:
		types |= DamageTypes.CRITICAL
	if types & DamageTypes.CRITICAL:
		damage *= 1.0 + origin_stats_node.crit_damage

	# randomize
	if not types & DamageTypes.NO_RANDOM:
		damage *= randf_range(0.97, 1.03)

	# clamp
	if types & DamageTypes.BREAK_LIMIT:
		damage = clamp(damage, -99999.0, 99999.0)
	else:
		damage = clamp(damage, -9999.0, 9999.0)
	
	# attempt miss
	# TODO: handle invincibility
	if not types & DamageTypes.NO_MISS and randf() < 0.25: # TODO: randf() < (target_stats_node.agility / 1028)
		types |= DamageTypes.MISS
		damage = 0.0

	# update target
	target_stats_node.update_health(damage)

	# display damage
	damage_display(abs(damage), target_stats_node.get_parent().position, types) # TODO: need to update

	return damage

func combat_buff(_buff: float, _types: Array[DamageTypes], _origin_stats_node: Node, _target_stats_node: Node) -> void:
	pass

func mana_depletion(_mana: float, _origin_stats_node: Node) -> void:
	pass

func stamina_depletion(_stamina: float, _origin_stats_node: Node) -> void:
	pass

func damage_display(damage: int, display_position: Vector2, types: int) -> void:
	if types & DamageTypes.HIDDEN:
		return
	
	var display = Label.new()
	display.text = str(damage)
	display.z_index = 5
	add_child(display)
	
	var color: String = "#FFF"
	if types & DamageTypes.MISS:
		display.text = "Miss"
		color = "#FFF8"
	elif types & DamageTypes.HEAL:
		color = "#3E3"
	elif types & DamageTypes.CRITICAL:
		color = "#FB0"
	elif types & DamageTypes.PLAYER_HIT:
		color = "#B22"

	display.set("theme_override_colors/font_color", color)
	display.set("theme_override_font_sizes/font_size", 16) # TODO: should scale on damage 7 to 16
	display.set("theme_override_colors/font_outline_color", "#000")
	display.set("theme_override_constants/outline_size", 1)

	display.position = display_position + Vector2(0, -5) - Vector2(display.size / 2) + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	display.pivot_offset = Vector2(display.size / 2)

	var tween = display.create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(display, "position:y", display.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(display, "position:y", display.position.y - 16, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(display, "scale", Vector2(0.75, 0.75), 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	
	await tween.finished
	display.queue_free()

func clear_damage_display() -> void:
	for display in get_children():
		display.queue_free()
