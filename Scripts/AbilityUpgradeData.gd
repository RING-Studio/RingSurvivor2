extends Node

@export var entries: Array[Dictionary] = [
	# 通用强化
	{
		"id": "crit_rate",
		"name": "暴击强化",
		"description": "暴击率 +{crit_rate_value}%",
		"quality": "blue",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "crit_damage",
		"name": "暴伤强化",
		"description": "暴击伤害 +{crit_damage_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "damage_bonus",
		"name": "伤害强化",
		"description": "伤害 +{damage_bonus_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "health",
		"name": "耐久强化",
		"description": "耐久 +{health_value}",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	# 主武器通用强化
	{
		"id": "rapid_fire",
		"name": "速射",
		"description": "射速 +{rapid_fire_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "chain_fire",
		"name": "连射",
		"description": "射速 -{chain_fire_penalty_value}%。主武器射击时，+3%射速，最多叠加{chain_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "scatter_shot",
		"name": "散弹",
		"description": "主武器每射击{scatter_shot_interval_value}次，向随机方向进行{scatter_shot_count_value}次额外射击",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "burst_fire",
		"name": "爆射",
		"description": "主武器暴击时，+4%射速，最多叠加{burst_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "sweep_fire",
		"name": "扫射",
		"description": "+{sweep_fire_bonus_value}%射速。主武器射击方向变更：顺时针旋转（每帧旋转固定角度）",
		"quality": "blue",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "chaos_fire",
		"name": "乱射",
		"description": "+100%射速。主武器射击方向变更：随机方向（每次射击完全随机）",
		"quality": "blue",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "breakthrough",
		"name": "破竹",
		"description": "场上存在的怪物数量越少，获得越多射速加成，最多+{breakthrough_max_bonus_value}%（怪物数量N，则+{breakthrough_max_bonus_value}%/N射速）",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "fire_suppression",
		"name": "火力压制",
		"description": "自身配件数量越多，获得越多射速加成（配件数量N，则+{fire_suppression_per_part_value}*N%射速）",
		"quality": "red",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "penetration",
		"name": "穿透",
		"description": "伤害 -{penetration_damage_penalty_value}%，主武器穿透+{penetration_penetration_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "windmill",
		"name": "风车",
		"description": "射速 -50%。伤害 -{windmill_damage_penalty_value}%。主武器弹道+{windmill_spread_value}。主武器射击方向变更：顺时针旋转",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "ricochet",
		"name": "弹射",
		"description": "主武器子弹命中后，有{ricochet_chance_value}%概率向最近敌人弹射。弹射在穿透前判定，成功则不消耗穿透次数",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "spread_shot",
		"name": "扩散",
		"description": "主武器弹道+{spread_shot_spread_value}，每发子弹造成{spread_shot_damage_ratio_value}%伤害",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "split_shot",
		"name": "分裂",
		"description": "主武器暴击时，子弹分裂成{split_shot_count_value}发，每发造成50%伤害。仅在弹射失败时触发，不消耗穿透次数。分裂子弹无法再分裂",
		"quality": "red",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "breath_hold",
		"name": "屏息",
		"description": "主武器未进行射击时，以+{breath_hold_rate_value}%/秒的速率给予暴击伤害加成。主武器射击后清空所有加成",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "focus",
		"name": "专注",
		"description": "主武器连续命中同一敌人时，每发+{focus_crit_rate_value}%暴击率，最多叠加5层。未命中该敌人时重新计算",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "harvest",
		"name": "收割",
		"description": "暴击击杀敌人时，恢复{harvest_heal_value}点耐久",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "lethal_strike",
		"name": "致命一击",
		"description": "主武器每射击{lethal_strike_interval_value}次，下一次射击暴击率+100%，且暴击伤害翻倍",
		"quality": "red",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	{
		"id": "crit_conversion",
		"name": "暴击转换",
		"description": "暴击时，暴击率加成会作用于暴击伤害加成",
		"quality": "red",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": ""
	},
	# 机炮专属强化
	{
		"id": "mg_overload",
		"name": "机炮·过载",
		"description": "射速 +50%，主武器射击时，-{mg_overload_penalty_value}%射速，最多叠加{mg_overload_max_stacks_value}层，每1秒减少{mg_overload_decay_value}层",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg"
	},
	{
		"id": "mg_heavy_round",
		"name": "机炮·重弹",
		"description": "射速 -{mg_heavy_round_penalty_value}%，主武器基础伤害+{mg_heavy_round_damage_value}",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg"
	},
	{
		"id": "mg_he_round",
		"name": "机炮·高爆弹",
		"description": "主武器基础伤害+3，穿透固定为1",
		"quality": "red",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg"
	},
	# 配件
	{
		"id": "mine",
		"name": "地雷",
		"description": "每{冷却时间}秒放置一个地雷，接触敌人后对{爆炸范围}范围内敌人造成{基础伤害=5lv}点伤害。部署上限：{mine_max_deployed_value}",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": ""
	},
	{
		"id": "cooling_device",
		"name": "冷却装置",
		"description": "所有配件冷却时间缩短{cooling_device_value}%",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": ""
	},
	# 地雷专属强化
	{
		"id": "mine_range",
		"name": "地雷·范围",
		"description": "地雷爆炸范围+{mine_range_value}米",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine"
	},
	{
		"id": "mine_cooldown",
		"name": "地雷·冷却",
		"description": "地雷冷却时间-{mine_cooldown_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine"
	},
	{
		"id": "mine_anti_tank",
		"name": "地雷·AT",
		"description": "地雷冷却时间+5秒，地雷基础伤害+{mine_anti_tank_value}%。地雷仅能由精英或BOSS触发",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine"
	}
]

# 升级图标映射：在编辑器中为每个升级配置对应的图标
@export var upgrade_icons: Dictionary = {
	# 通用强化
	"health": preload("res://Assets/GPT/ChatGPT shield.png"),
	"crit_rate": preload("res://Assets/GPT/ChatGPT crit.png"),
	"crit_damage": preload("res://Assets/GPT/ChatGPT crit.png"),
	"damage_bonus": null,
}

func get_entry(upgrade_id):
	for entry in entries:
		if entry.get("id") == upgrade_id:
			return entry
	return null

func get_icon(upgrade_id: String) -> Texture2D:
	"""获取升级对应的图标"""
	return upgrade_icons.get(upgrade_id, null)
