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
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "crit_damage",
		"name": "暴伤强化",
		"description": "暴击伤害 +{crit_damage_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "damage_bonus",
		"name": "伤害强化",
		"description": "伤害 +{damage_bonus_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "health",
		"name": "耐久强化",
		"description": "耐久 +{health_value}",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	# 主武器通用强化
	{
		"id": "rapid_fire",
		"name": "速射",
		"description": "射速 +{rapid_fire_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "chain_fire",
		"name": "连射",
		"description": "射速 -{chain_fire_penalty_value}%。主武器射击时，+3%射速，最多叠加{chain_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "scatter_shot",
		"name": "散弹",
		"description": "主武器每射击{scatter_shot_interval_value}次，向随机方向进行{scatter_shot_count_value}次额外射击",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "burst_fire",
		"name": "爆射",
		"description": "主武器暴击时，+4%射速，最多叠加{burst_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "sweep_fire",
		"name": "扫射",
		"description": "主武器射击方向变更-扫射*：主武器射击方向旋转追踪最近敌人\n射速 +{sweep_fire_bonus_value}%",
		"quality": "blue",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": "fire_direction"
	},
	{
		"id": "chaos_fire",
		"name": "乱射",
		"description": "主武器射击方向变更-乱射*：主武器射击方向随机（每次射击完全随机方向）\n射速 +100%",
		"quality": "blue",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": "fire_direction"
	},
	{
		"id": "breakthrough",
		"name": "破竹",
		"description": "场上存在的怪物数量越少，获得越多射速加成，最多+{breakthrough_max_bonus_value}%（怪物数量N，则+{breakthrough_max_bonus_value}%/N射速）",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "fire_suppression",
		"name": "火力压制",
		"description": "自身配件数量越多，获得越多射速加成（配件数量N，则+{fire_suppression_per_part_value}*N%射速）",
		"quality": "red",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "penetration",
		"name": "穿透",
		"description": "伤害 -{penetration_damage_penalty_value}%，主武器穿透+{penetration_penetration_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "windmill",
		"name": "风车",
		"description": "主武器射击方向变更-风车*：主武器射击方向随时间顺时针旋转，各弹道均匀分布\n射速 -50%\n伤害 -20%\n主武器弹道+2",
		"quality": "blue",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": "fire_direction"
	},
	# 风车衍生强化
	{
		"id": "windmill_spread",
		"name": "风车·弹道",
		"description": "伤害 -{windmill_spread_damage_penalty_value}%\n主武器弹道+{windmill_spread_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "windmill",
		"prefix": ""
	},
	{
		"id": "windmill_speed",
		"name": "风车·转速",
		"description": "射速 +{windmill_speed_fire_rate_value}%\n风车旋转速度 +{windmill_speed_rotation_value}%",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "windmill",
		"prefix": ""
	},
	{
		"id": "ricochet",
		"name": "弹射",
		"description": "主武器子弹命中后，有{ricochet_chance_value}%概率向最近敌人弹射。弹射在穿透前判定，成功则不消耗穿透次数",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "spread_shot",
		"name": "扩散",
		"description": "主武器弹道+{spread_shot_spread_value}，每发子弹造成{spread_shot_damage_ratio_value}%伤害",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "split_shot",
		"name": "分裂",
		"description": "主武器暴击时，子弹分裂成{split_shot_count_value}发，每发造成50%伤害。仅在弹射失败时触发，不消耗穿透次数。分裂子弹无法再分裂",
		"quality": "red",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "breath_hold",
		"name": "屏息",
		"description": "主武器未进行射击时，以+{breath_hold_rate_value}%/秒的速率给予暴击伤害加成。主武器射击后清空所有加成",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "focus",
		"name": "专注",
		"description": "主武器连续命中同一敌人时，每发+{focus_crit_rate_value}%暴击率，最多叠加5层。未命中该敌人时重新计算",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "harvest",
		"name": "收割",
		"description": "暴击击杀敌人时，恢复{harvest_heal_value}点耐久",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "lethal_strike",
		"name": "致命一击",
		"description": "主武器每射击{lethal_strike_interval_value}次，下一次射击暴击率+100%，且暴击伤害翻倍",
		"quality": "red",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "crit_conversion",
		"name": "暴击转换",
		"description": "暴击时，暴击率加成会作用于暴击伤害加成",
		"quality": "red",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	# 机炮专属强化
	{
		"id": "mg_overload",
		"name": "机炮·过载",
		"description": "射速 +50%，主武器射击时，-{mg_overload_penalty_value}%射速，最多叠加{mg_overload_max_stacks_value}层，每1秒减少{mg_overload_decay_value}层",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg",
		"prefix": ""
	},
	{
		"id": "mg_heavy_round",
		"name": "机炮·重弹",
		"description": "射速 -{mg_heavy_round_penalty_value}%，主武器基础伤害+{mg_heavy_round_damage_value}",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg",
		"prefix": ""
	},
	{
		"id": "mg_he_round",
		"name": "机炮·高爆弹",
		"description": "主武器基础伤害+3，穿透固定为1",
		"quality": "red",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "mg",
		"prefix": ""
	},
	# 榴弹炮专属强化
	{
		"id": "howitzer_reload",
		"name": "榴弹炮·装填",
		"description": "榴弹炮射速 +{howitzer_reload_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "howitzer",
		"prefix": ""
	},
	{
		"id": "howitzer_radius",
		"name": "榴弹炮·爆炸半径",
		"description": "榴弹炮爆炸范围 +{howitzer_radius_value}米",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "howitzer",
		"prefix": ""
	},
	# 坦克炮专属强化
	{
		"id": "tank_gun_depth",
		"name": "坦克炮·穿深",
		"description": "坦克炮硬攻深度 +{tank_gun_depth_value}mm",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "tank_gun",
		"prefix": ""
	},
	{
		"id": "tank_gun_penetration",
		"name": "坦克炮·穿透",
		"description": "坦克炮穿透 +{tank_gun_penetration_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "tank_gun",
		"prefix": ""
	},
	# 导弹主武器专属强化
	{
		"id": "missile_salvo",
		"name": "导弹·齐射",
		"description": "每次发射额外 +{missile_salvo_value} 枚导弹",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "missile",
		"prefix": ""
	},
	{
		"id": "missile_reload",
		"name": "导弹·装填",
		"description": "导弹射速 +{missile_reload_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "missile",
		"prefix": ""
	},
	# 配件
	{
		"id": "mine",
		"name": "地雷",
		"description": "放置一个地雷，接触敌人后对{爆炸范围}米范围内敌人造成{基础伤害=5lv}点伤害。\n基础装填间隔：{冷却时间}秒\n部署上限：{mine_max_deployed_value}",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "cooling_device",
		"name": "冷却装置",
		"description": "所有【冷却类】配件冷却速度 +{cooling_device_value}%",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	# 地雷专属强化
	{
		"id": "mine_range",
		"name": "地雷·范围",
		"description": "地雷爆炸范围+{mine_range_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine",
		"prefix": ""
	},
	{
		"id": "mine_cooldown",
		"name": "地雷·装填速度",
		"description": "地雷装填速度 +{mine_cooldown_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine",
		"prefix": ""
	},
	{
		"id": "mine_multi_deploy",
		"name": "地雷·布雷",
		"description": "地雷基础伤害 -{mine_multi_damage_penalty}\n每次部署地雷数量 +{mine_multi_deploy_count}",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine",
		"prefix": ""
	},
	{
		"id": "mine_anti_tank",
		"name": "地雷·AT",
		"description": "地雷装填间隔 +5秒，地雷基础伤害+{mine_anti_tank_value}%。地雷仅能由精英或BOSS触发",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "mine",
		"prefix": ""
	},
	# ========== 阶段三：通用生存/机动/防御 ==========
	{
		"id": "repair_kit",
		"name": "维护工具箱",
		"description": "每{repair_kit_interval_value}秒回复 1 点耐久",
		"quality": "white",
		"max_level": 9,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "cabin_ac",
		"name": "车载空调",
		"description": "回复耐久时，冷却速度 +{cabin_ac_value}%，持续3秒。不可叠加。",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "heat_sink",
		"name": "散热器",
		"description": "耐久上限 -{heat_sink_penalty_value}。耐久上限越低，全局冷却速度越快（+{heat_sink_cooling_desc}）",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "christie_suspension",
		"name": "克里斯蒂悬挂",
		"description": "移速 +{christie_suspension_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "gas_turbine",
		"name": "燃气轮机",
		"description": "移速 +{gas_turbine_value}%",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "hydro_pneumatic",
		"name": "液气悬挂",
		"description": "受到的移速惩罚减半",
		"quality": "purple",
		"max_level": 1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "addon_armor",
		"name": "车身附加装甲",
		"description": "耐久 +{addon_armor_health_value}，被击穿时受到的伤害减免 {addon_armor_reduction_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "relief_valve",
		"name": "泄压阀",
		"description": "被击穿时受到的伤害减免 {relief_valve_value}%",
		"quality": "blue",
		"max_level": 6,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段四：配件系统扩展 ==========
	{
		"id": "smoke_grenade",
		"name": "烟雾弹",
		"description": "原地释放烟雾，{smoke_radius_value}米范围内敌人移速 -{smoke_slow_value}%，持续{smoke_duration_value}秒。\n装填：10秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "radio_support",
		"name": "无线电通讯",
		"description": "呼叫炮击锁定随机区域，10秒后在该区域造成范围伤害。\n基础伤害：{radio_damage_value}\n范围：{radio_radius_value}米\n冷却：{radio_cooldown_value}秒",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "laser_suppress",
		"name": "激光压制",
		"description": "开启后{laser_duration_value}秒内，对{laser_range_value}米范围内最近敌人每秒造成{laser_hits_per_second_value}次伤害。\n基础伤害：{laser_damage_value}\n冷却：{laser_cooldown_value}秒",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "external_missile",
		"name": "外挂导弹",
		"description": "对{missile_lock_range_value}米内最近敌人发射导弹，命中后爆炸造成范围伤害。\n基础伤害：{missile_damage_value}\n爆炸范围：{missile_radius_value}米\n冷却：{missile_cooldown_value}秒",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "spall_liner",
		"name": "纤维内衬",
		"description": "被动：抵御一次致命击穿伤害，触发后失效",
		"quality": "blue",
		"max_level": 1,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "era_block",
		"name": "爆炸反应装甲",
		"description": "被动：抵御一次任意致命伤害，触发后失效。优先于纤维内衬触发",
		"quality": "purple",
		"max_level": 1,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "ir_counter",
		"name": "红外对抗",
		"description": "5米范围内正在瞄准玩家的最近的远程敌人穿甲率固定为0%",
		"quality": "red",
		"max_level": 1,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	# 配件专属强化（示例：烟雾弹/无线电/导弹）
	{
		"id": "smoke_range",
		"name": "烟雾弹·范围",
		"description": "烟雾弹影响范围 +{smoke_range_value}米",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "smoke_grenade",
		"prefix": ""
	},
	{
		"id": "smoke_duration",
		"name": "烟雾弹·持续",
		"description": "烟雾弹持续时间 +{smoke_duration_bonus_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "smoke_grenade",
		"prefix": ""
	},
	{
		"id": "radio_radius",
		"name": "无线电·半径",
		"description": "炮击影响半径 +{radio_radius_bonus_value}米",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "radio_support",
		"prefix": ""
	},
	{
		"id": "missile_damage",
		"name": "外挂导弹·伤害",
		"description": "外挂导弹基础伤害 +{missile_damage_bonus_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "external_missile",
		"prefix": ""
	}
]

# 升级图标映射：在编辑器中为每个升级配置对应的图标
@export var upgrade_icons: Dictionary = {
	# 通用强化
	"health": preload("res://Assets/GPT/ChatGPT shield.png"),
	"crit_rate": preload("res://Assets/GPT/ChatGPT crit.png"),
	"crit_damage": preload("res://Assets/GPT/ChatGPT crit.png"),
    "mine": preload("res://Assets/GPT/ChatGPT mine.png"),
	"smoke_grenade": null,
	"radio_support": null,
	"laser_suppress": null,
	"external_missile": null,
	"ir_counter": null,
	"howitzer_reload": null,
	"howitzer_radius": null,
	"tank_gun_depth": null,
	"tank_gun_penetration": null,
	"missile_salvo": null,
	"missile_reload": null,
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
