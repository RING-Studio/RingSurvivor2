extends Node

@export var entries: Array[Dictionary] = [
	# 通用强化
	{
		"id": "global_health_1",
		"name": "耐久强化Ⅰ",
		"description": "耐久 +2",
		"quality": "white",
		"max_level": -1
	},
	{
		"id": "global_crit_rate_1",
		"name": "精准强化Ⅰ",
		"description": "通用暴击率 +1%",
		"quality": "white",
		"max_level": 5
	},
	{
		"id": "global_health_2",
		"name": "耐久强化Ⅱ",
		"description": "耐久 +3",
		"quality": "blue",
		"max_level": -1
	},
	{
		"id": "global_crit_rate_2",
		"name": "精准强化Ⅱ",
		"description": "通用暴击率 +2%",
		"quality": "purple",
		"max_level": 5
	},
	{
		"id": "global_health_3",
		"name": "耐久强化Ⅲ",
		"description": "耐久 +5",
		"quality": "purple",
		"max_level": -1
	},
	{
		"id": "global_health_4",
		"name": "耐久强化Ⅳ",
		"description": "耐久 +8",
		"quality": "red",
		"max_level": -1
	},
	# 机炮专属强化
	{
		"id": "mg_fire_rate_1",
		"name": "机炮射速强化Ⅰ",
		"description": "机炮射速 +10%",
		"quality": "white",
		"max_level": 10
	},
	{
		"id": "mg_precision_1",
		"name": "机炮精准强化Ⅰ",
		"description": "机炮暴击率 +2%",
		"quality": "white",
		"max_level": -1
	},
	{
		"id": "mg_fire_rate_2",
		"name": "机炮射速强化Ⅱ",
		"description": "机炮射速 +15%",
		"quality": "blue",
		"max_level": 8
	},
	{
		"id": "mg_precision_2",
		"name": "机炮精准强化Ⅱ",
		"description": "机炮暴击率 +3%",
		"quality": "blue",
		"max_level": -1
	},
	{
		"id": "mg_crit_damage",
		"name": "机炮暴击强化",
		"description": "机炮暴击伤害 +10%",
		"quality": "blue",
		"max_level": -1
	},
	{
		"id": "mg_damage_1",
		"name": "机炮伤害强化Ⅰ",
		"description": "机炮基础伤害 +1",
		"quality": "purple",
		"max_level": -1
	},
	{
		"id": "mg_precision_3",
		"name": "机炮精准强化Ⅲ",
		"description": "机炮暴击率 +4%",
		"quality": "purple",
		"max_level": -1
	},
	{
		"id": "mg_fire_rate_3",
		"name": "机炮射速强化Ⅲ",
		"description": "机炮射速 +20%",
		"quality": "purple",
		"max_level": 5
	},
	{
		"id": "mg_penetration",
		"name": "机炮穿透强化",
		"description": "机炮穿透次数 +1",
		"quality": "purple",
		"max_level": 5
	},
	{
		"id": "mg_rapid_fire_1",
		"name": "机炮激射Ⅰ",
		"description": "造成暴击时，下一次射击暴击伤害翻倍（不可叠加）",
		"quality": "purple",
		"max_level": 1
	},
	{
		"id": "mg_rapid_fire_2",
		"name": "机炮激射Ⅱ",
		"description": "造成暴击时，下一次射击+1穿透",
		"quality": "purple",
		"max_level": 1
	},
	{
		"id": "mg_damage_2",
		"name": "机炮伤害强化Ⅱ",
		"description": "机炮基础伤害 +2",
		"quality": "red",
		"max_level": -1
	},
	{
		"id": "mg_spread",
		"name": "机炮弹道扩散",
		"description": "机炮弹道 +1",
		"quality": "red",
		"max_level": 5
	},
	{
		"id": "mg_rapid_fire_3",
		"name": "机炮激射Ⅲ",
		"description": "造成暴击时，下一次射击+1弹道",
		"quality": "red",
		"max_level": 1
	},
	{
		"id": "mg_bleed",
		"name": "机炮溅血",
		"description": "暴击时施加 1 层流血",
		"quality": "red",
		"max_level": 3
	}
]

# 升级图标映射：在编辑器中为每个升级配置对应的图标
@export var upgrade_icons: Dictionary = {
	# 通用强化
	"global_health_1": preload("res://Assets/GPT/ChatGPT shield.png"),
	"global_health_2": preload("res://Assets/GPT/ChatGPT shield.png"),
	"global_health_3": preload("res://Assets/GPT/ChatGPT shield.png"),
	"global_health_4": preload("res://Assets/GPT/ChatGPT shield.png"),
	"global_crit_rate_1": preload("res://Assets/GPT/ChatGPT crit.png"),
	"global_crit_rate_2": preload("res://Assets/GPT/ChatGPT crit.png"),
	
	# 机炮专属强化
	"mg_fire_rate_1": null,
	"mg_precision_1": null,
	"mg_fire_rate_2": null,
	"mg_precision_2": null,
	"mg_crit_damage": null,
	"mg_damage_1": null,
	"mg_precision_3": null,
	"mg_fire_rate_3": null,
	"mg_penetration": null,
	"mg_rapid_fire_1": null,
	"mg_rapid_fire_2": null,
	"mg_damage_2": null,
	"mg_spread": preload("res://Assets/GPT/ChatGPT split.png"),
	"mg_rapid_fire_3": null,
	"mg_bleed": null,
}

func get_entry(upgrade_id):
	for entry in entries:
		if entry.get("id") == upgrade_id:
			return entry
	return null

func get_icon(upgrade_id: String) -> Texture2D:
	"""获取升级对应的图标"""
	return upgrade_icons.get(upgrade_id, null)
