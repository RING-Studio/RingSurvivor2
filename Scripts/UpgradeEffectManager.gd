extends Node
class_name UpgradeEffectManager

# 升级效果配置
# 格式：{ upgrade_id: { type: "linear"/"custom", ... } }
static var upgrade_configs: Dictionary = {
	# ========== 通用强化 ==========
	
	# 暴击强化：每级 +3%，无限等级
	"crit_rate": {
		"type": "linear",
		"per_level_value": 0.03
	},
	
	# 暴伤强化：每级 +6%，无限等级
	"crit_damage": {
		"type": "linear",
		"per_level_value": 0.06
	},
	
	# 伤害强化：每级 +5%，无限等级
	"damage_bonus": {
		"type": "linear",
		"per_level_value": 0.05
	},
	
	# 耐久强化：每级 +5，无限等级
	"health": {
		"type": "linear",
		"per_level_value": 5.0
	},
	
	# ========== 主武器通用强化 ==========
	
	# 速射：每级 +5%，无限等级
	"rapid_fire": {
		"type": "linear",
		"per_level_value": 0.05
	},
	
	# 连射：每级效果在 WeaponUpgradeHandler 中处理
	"chain_fire": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 散弹：每级效果在 WeaponUpgradeHandler 中处理
	"scatter_shot": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 爆射：每级效果在 WeaponUpgradeHandler 中处理
	"burst_fire": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 10
	},
	
	# 扫射：每级 +50%射速，最大2级
	"sweep_fire": {
		"type": "linear",
		"per_level_value": 0.50,
		"max_level": 2
	},
	
	# 乱射：+100%射速，唯一
	"chaos_fire": {
		"type": "custom",
		"level_effects": {
			1: 1.0
		}
	},
	
	# 破竹：每级效果在 WeaponUpgradeHandler 中处理
	"breakthrough": {
		"type": "linear",
		"per_level_value": 0.25,
		"max_level": 3
	},
	
	# 火力压制：每级效果在 WeaponUpgradeHandler 中处理
	"fire_suppression": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 2
	},
	
	# 穿透：每级效果在 WeaponUpgradeHandler 中处理
	"penetration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 风车：每级效果在 WeaponUpgradeHandler 中处理
	"windmill": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 1
	},
	
	# 弹射：每级效果在 WeaponUpgradeHandler 中处理
	"ricochet": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 4
	},
	
	# 扩散：每级效果在 WeaponUpgradeHandler 中处理
	"spread_shot": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	
	# 分裂：每级效果在 WeaponUpgradeHandler 中处理
	"split_shot": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 2
	},
	
	# 屏息：每级效果在 WeaponUpgradeHandler 中处理
	"breath_hold": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 10
	},
	
	# 专注：每级效果在 WeaponUpgradeHandler 中处理
	"focus": {
		"type": "linear",
		"per_level_value": 0.01,
		"max_level": 5
	},
	
	# 收割：每级恢复1点耐久，最大5级
	"harvest": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 致命一击：每级效果在 WeaponUpgradeHandler 中处理
	"lethal_strike": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	
	# 暴击转换：唯一
	"crit_conversion": {
		"type": "custom",
		"level_effects": {
			1: 1.0
		}
	},
	
	# ========== 机炮专属新强化 ==========
	
	# 机炮·过载：每级效果在 WeaponUpgradeHandler 中处理
	"mg_overload": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	
	# 机炮·重弹：每级 -10%射速，+1基础伤害，最大5级
	"mg_heavy_round": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 机炮·高爆弹：基础伤害+3，穿透固定为1，唯一
	"mg_he_round": {
		"type": "custom",
		"level_effects": {
			1: 1.0
		}
	},
	
	# ========== 配件相关 ==========
	
	# 地雷：每级效果在 MineAbilityController 中处理
	"mine": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	
	# 地雷·范围：每级 +1.5米
	"mine_range": {
		"type": "linear",
		"per_level_value": 1.5,
		"max_level": 5
	},
	
	# 地雷·装填速度：每级 +15%（速度加成）
	"mine_cooldown": {
		"type": "linear",
		"per_level_value": 0.15,
		"max_level": 5
	},
	
	# 地雷·AT：每级 +200%伤害
	"mine_anti_tank": {
		"type": "linear",
		"per_level_value": 2.0,
		"max_level": 5
	},
	
	# 冷却装置：每级 +15%（冷却速度加成，仅冷却类配件）
	"cooling_device": {
		"type": "linear",
		"per_level_value": 0.15,
		"max_level": 3
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
