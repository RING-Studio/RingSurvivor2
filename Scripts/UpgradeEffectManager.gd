extends Node
class_name UpgradeEffectManager

# 升级效果配置
# 格式：{ upgrade_id: { type: "linear"/"custom", ... } }
static var upgrade_configs: Dictionary = {
	# ========== 机炮专属强化 ==========
	
	# 机炮射速强化Ⅰ：每级 +10%，最大10级
	"mg_fire_rate_1": {
		"type": "linear",
		"per_level_value": 0.10,  # 每级增加10%
		"max_level": 10
	},
	
	# 机炮射速强化Ⅱ：每级 +15%，最大8级
	"mg_fire_rate_2": {
		"type": "linear",
		"per_level_value": 0.15,
		"max_level": 8
	},
	
	# 机炮射速强化Ⅲ：每级 +20%，最大5级
	"mg_fire_rate_3": {
		"type": "linear",
		"per_level_value": 0.20,
		"max_level": 5
	},
	
	# 机炮精准强化Ⅰ：每级 +2%，无限等级
	"mg_precision_1": {
		"type": "linear",
		"per_level_value": 0.02
	},
	
	# 机炮精准强化Ⅱ：每级 +3%，无限等级
	"mg_precision_2": {
		"type": "linear",
		"per_level_value": 0.03
	},
	
	# 机炮精准强化Ⅲ：每级 +4%，无限等级
	"mg_precision_3": {
		"type": "linear",
		"per_level_value": 0.04
	},
	
	# 机炮暴击强化：每级 +10%，无限等级
	"mg_crit_damage": {
		"type": "linear",
		"per_level_value": 0.10
	},
	
	# 机炮伤害强化Ⅰ：每级 +1，无限等级
	"mg_damage_1": {
		"type": "linear",
		"per_level_value": 1.0
	},
	
	# 机炮伤害强化Ⅱ：每级 +2，无限等级
	"mg_damage_2": {
		"type": "linear",
		"per_level_value": 2.0
	},
	
	# 机炮穿透强化：每级 +1，最大5级
	"mg_penetration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 机炮弹道扩散：每级 +1，最大5级
	"mg_spread": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 机炮溅血：每级 +1层，最大3级
	"mg_bleed": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	
	# 机炮激射Ⅰ：唯一，效果为1（表示已激活）
	"mg_rapid_fire_1": {
		"type": "custom",
		"level_effects": {
			1: 1.0  # 激活后效果值为1
		}
	},
	
	# 机炮激射Ⅱ：唯一，效果为1
	"mg_rapid_fire_2": {
		"type": "custom",
		"level_effects": {
			1: 1.0
		}
	},
	
	# 机炮激射Ⅲ：唯一，效果为1
	"mg_rapid_fire_3": {
		"type": "custom",
		"level_effects": {
			1: 1.0
		}
	},
	
	# ========== 通用强化 ==========
	
	# 耐久强化Ⅰ：每级 +2，无限等级
	"global_health_1": {
		"type": "linear",
		"per_level_value": 2.0
	},
	
	# 耐久强化Ⅱ：每级 +3，无限等级
	"global_health_2": {
		"type": "linear",
		"per_level_value": 3.0
	},
	
	# 耐久强化Ⅲ：每级 +5，无限等级
	"global_health_3": {
		"type": "linear",
		"per_level_value": 5.0
	},
	
	# 耐久强化Ⅳ：每级 +8，无限等级
	"global_health_4": {
		"type": "linear",
		"per_level_value": 8.0
	},
	
	# 精准强化Ⅰ：每级 +1%，最大5级
	"global_crit_rate_1": {
		"type": "linear",
		"per_level_value": 0.01,
		"max_level": 5
	},
	
	# 精准强化Ⅱ：每级 +2%，最大5级
	"global_crit_rate_2": {
		"type": "linear",
		"per_level_value": 0.02,
		"max_level": 5
	}
}

# 获取升级在指定等级的效果值
static func get_effect(upgrade_id: String, level: int) -> float:
	if level <= 0:
		return 0.0
	
	var config = upgrade_configs.get(upgrade_id)
	if config == null:
		push_warning("未找到升级配置: %s" % upgrade_id)
		return 0.0
	
	var effect_type = config.get("type", "linear")
	
	match effect_type:
		"linear":
			# 线性计算：level * per_level_value
			var per_level_value = config.get("per_level_value", 0.0)
			return float(level) * per_level_value
		
		"custom":
			# 自定义：从 level_effects 字典中查找
			var level_effects = config.get("level_effects", {})
			if level_effects.has(level):
				return level_effects[level]
			
			# 如果等级超出定义范围，返回最高等级的效果
			if level_effects.size() > 0:
				var max_level = level_effects.keys().max()
				return level_effects[max_level]
			
			return 0.0
	
	return 0.0

# 获取升级配置（用于调试或UI显示）
static func get_config(upgrade_id: String) -> Dictionary:
	return upgrade_configs.get(upgrade_id, {})
