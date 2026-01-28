extends Node

# 伤害来源颜色映射
var SOURCE_COLORS := {
	"weapon": Color(1, 1, 1, 1),      # 白色
	"accessory": Color(1, 1, 1, 1),  # 白色（与武器相同）
	"bleed": Color(0.9, 0.2, 0.4, 1) # 绯红色
}

# 暴击颜色（覆盖伤害来源颜色）
var CRITICAL_COLOR := Color(1, 0.93, 0.2, 1)  # 黄色

func get_color(damage_source: String, is_critical: bool = false) -> Color:
	"""
	获取伤害数字颜色
	damage_source: "weapon" | "accessory" | "bleed"
	is_critical: 是否暴击
	"""
	if is_critical:
		return CRITICAL_COLOR
	
	return SOURCE_COLORS.get(damage_source, SOURCE_COLORS["weapon"])
