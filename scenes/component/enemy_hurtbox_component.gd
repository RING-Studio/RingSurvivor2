extends HurtboxComponent
class_name EnemyHurtboxComponent

func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return
	
	if health_component == null:
		return
	
	var hitbox_component = other_area as HitboxComponent
	
	# 使用父类的统一方法，传入damage_type
	apply_damage(hitbox_component.damage, hitbox_component.damage_type)
	
	hit.emit()
