extends Node

#def damage(基础伤害: float, 硬攻倍率: float, 软攻倍率: float, 硬攻深度: int, 敌方装甲厚度: int, 敌方覆甲率: float, 敌方硬攻伤害减免: float) -> int:
func calculate_damage( base_damage: float, hard_multiplier: float, soft_multiplier: float, hard_attack_depth_mm: int, enemy_armor_thickness: int, enemy_armor_coverage: float, enemy_hard_attack_damage_reduction: float) -> int:

	var hard_attack = base_damage * hard_multiplier
	var soft_attack = base_damage * soft_multiplier

	var dmg = 0
	if hard_attack_depth_mm > enemy_armor_thickness:  # hard attack penetration
		dmg = hard_attack + soft_attack * (1 - enemy_armor_coverage)
		var hard_attack_damage = hard_attack * enemy_armor_coverage
		dmg -= hard_attack_damage * enemy_hard_attack_damage_reduction
	else:  # no hard attack penetration
		dmg = (hard_attack + soft_attack) * (1 - enemy_armor_coverage)

	return int(dmg)  # use max(int(dmg), 0) if you want to block negatives


enum PollutionLevel {
	GOOD,
	LIGHT,
	MODERATE,
	SEVERE,
	OVERLOAD
}

func get_pollution_level(pollution: float) -> PollutionLevel:
	if pollution < 3000.0:
		return PollutionLevel.GOOD
	elif pollution < 6000.0:
		return PollutionLevel.LIGHT
	elif pollution < 8000.0:
		return PollutionLevel.MODERATE
	elif pollution < 10000.0:
		return PollutionLevel.SEVERE
	else:
		return PollutionLevel.OVERLOAD


func pollution_level_to_chinese(level: PollutionLevel) -> String:
	match level:
		PollutionLevel.GOOD:
			return "良好"
		PollutionLevel.LIGHT:
			return "轻度"
		PollutionLevel.MODERATE:
			return "中度"
		PollutionLevel.SEVERE:
			return "重度"
		PollutionLevel.OVERLOAD:
			return "爆表"
		_:
			return "未知"

			
