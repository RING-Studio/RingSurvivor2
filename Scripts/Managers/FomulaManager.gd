extends Node

#def damage(基础伤害: int, 基础伤害修改比例: float, 穿甲攻击倍率: float, 软攻倍率: float, 穿深: int, 敌方装甲厚度: int, 敌方覆甲率: float, 敌方击穿伤害减免: float) -> int:
func calculate_damage( base_damage: int, base_damage_modifier: float, hard_multiplier: float, soft_multiplier: float, penetration: int, enemy_armor_thickness: int, enemy_armor_coverage: float, enemy_penetration_damage_reduction: float) -> int:

	var hard_attack = base_damage * base_damage_modifier * hard_multiplier
	var soft_attack = base_damage * base_damage_modifier * soft_multiplier

	var dmg = 0
	if penetration > enemy_armor_thickness:  # penetration
		dmg = hard_attack + soft_attack * (1 - enemy_armor_coverage)
		var penetration_damage = hard_attack * enemy_armor_coverage
		dmg -= penetration_damage * enemy_penetration_damage_reduction
	else:  # no penetration
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

			
