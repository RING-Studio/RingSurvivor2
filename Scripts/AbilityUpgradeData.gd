extends Node

@export var entries: Array[Dictionary] = [
	{
		"id": "mg_fire_rate_1",
		"name": "射速强化Ⅰ",
		"description": "射速 +10%",
		"quality": "white",
		"weight": 12,
		"max_level": 20
	},
	{
		"id": "mg_precision_1",
		"name": "精准强化Ⅰ",
		"description": "暴击率 +2%",
		"quality": "white",
		"weight": 10,
		"max_level": -1
	},
	{
		"id": "mg_damage_modifier",
		"name": "伤害修改强化",
		"description": "伤害修改比例 +5%",
		"quality": "white",
		"weight": 8,
		"max_level": -1
	},
	{
		"id": "mg_fire_rate_2",
		"name": "射速强化Ⅱ",
		"description": "射速 +15%",
		"quality": "blue",
		"weight": 10,
		"max_level": 15
	},
	{
		"id": "mg_damage_1",
		"name": "伤害强化Ⅰ",
		"description": "基础伤害 +1",
		"quality": "blue",
		"weight": 9,
		"max_level": -1
	},
	{
		"id": "mg_precision_2",
		"name": "精准强化Ⅱ",
		"description": "暴击率 +3%",
		"quality": "blue",
		"weight": 9,
		"max_level": -1
	},
	{
		"id": "mg_crit_damage",
		"name": "暴击强化",
		"description": "暴击伤害 +10%",
		"quality": "blue",
		"weight": 8,
		"max_level": -1
	},
	{
		"id": "mg_damage_2",
		"name": "伤害强化Ⅱ",
		"description": "基础伤害 +2",
		"quality": "purple",
		"weight": 6,
		"max_level": -1
	},
	{
		"id": "mg_penetration",
		"name": "穿透强化",
		"description": "穿透次数 +1",
		"quality": "purple",
		"weight": 6,
		"max_level": -1
	},
	{
		"id": "mg_precision_3",
		"name": "精准强化Ⅲ",
		"description": "暴击率 +4%",
		"quality": "purple",
		"weight": 5,
		"max_level": -1
	},
	{
		"id": "mg_fire_rate_3",
		"name": "射速强化Ⅲ",
		"description": "射速 +20%",
		"quality": "purple",
		"weight": 5,
		"max_level": 10
	},
	{
		"id": "mg_spread",
		"name": "弹道扩散",
		"description": "弹道 +1",
		"quality": "red",
		"weight": 4,
		"max_level": 5
	},
	{
		"id": "mg_splash",
		"name": "碎片溅射",
		"description": "产生溅射 +1",
		"quality": "red",
		"weight": 4,
		"max_level": 5
	},
	{
		"id": "mg_bleed",
		"name": "溅血强化",
		"description": "暴击时，对敌人施加*基础伤害*层流血",
		"quality": "red",
		"weight": 4,
		"max_level": 5
	}
]

func get_entry(upgrade_id):
	for entry in entries:
		if entry.get("id") == upgrade_id:
			return entry
	return null
