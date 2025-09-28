extends HurtboxComponent
class_name EnemyHurtboxComponent

func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return
	
	if health_component == null:
		return
	
	var hitbox_component = other_area as HitboxComponent
	var body = get_parent()
	
	var damage = GlobalFomulaManager.calculate_damage(GameManager.get_player_base_damage(), 
													  GameManager.get_player_base_damage_modifier_ratio(),
													  GameManager.get_player_penetration_attack_multiplier_percent(),
													  GameManager.get_player_soft_attack_multiplier_percent(), 
													  GameManager.get_player_penetration_depth_mm(),
													  body.armor_thickness,
													  body.armorCoverage,
													  0)

	health_component.damage(damage)
	
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	
	floating_text.global_position = global_position + (Vector2.UP * 16)
	
	var format_string = "%d"
	# if round(hitbox_component.damage) == damage:
	# 	format_string = "%0.0f"
	floating_text.start(format_string % [damage])
	
	hit.emit()
