extends Node

@export var entries: Array[Dictionary] = [
	# 通用强化
	{
		"id": "crit_rate",
		"name": "精准校射",
		"description": "暴击率 +{crit_rate_value}%",
		"quality": "blue",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "crit_damage",
		"name": "要害瞄具",
		"description": "暴击伤害 +{crit_damage_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "damage_bonus",
		"name": "增效装药",
		"description": "伤害 +{damage_bonus_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "health",
		"name": "加固结构",
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
		"name": "高速供弹",
		"description": "射速 +{rapid_fire_value}%",
		"quality": "white",
		"max_level": -1,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "chain_fire",
		"name": "连发回路",
		"description": "射速 -{chain_fire_penalty_value}%。主武器射击时，+3%射速，最多叠加{chain_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "scatter_shot",
		"name": "余弹",
		"description": "主武器每射击{scatter_shot_interval_value}次，向随机方向进行{scatter_shot_count_value}次额外射击",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "burst_fire",
		"name": "应激扳机",
		"description": "主武器暴击时，+4%射速，最多叠加{burst_fire_max_stacks_value}层，每1秒减少1层",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "sweep_fire",
		"name": "伺服追踪",
		"description": "主武器射击方向变更-扫射*：主武器射击方向旋转追踪最近敌人\n射速 +{sweep_fire_bonus_value}%",
		"quality": "blue",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": "fire_direction"
	},
	{
		"id": "chaos_fire",
		"name": "暴走",
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
		"name": "贯穿弹芯",
		"description": "伤害 -{penetration_damage_penalty_value}%，主武器穿透+{penetration_penetration_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "windmill",
		"name": "回转射界",
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
		"name": "回转射界·增程弹道",
		"description": "伤害 -{windmill_spread_damage_penalty_value}%\n主武器弹道+{windmill_spread_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "windmill",
		"prefix": ""
	},
	{
		"id": "windmill_speed",
		"name": "回转射界·角速驱动",
		"description": "射速 +{windmill_speed_fire_rate_value}%\n风车旋转速度 +{windmill_speed_rotation_value}%",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "windmill",
		"prefix": ""
	},
	{
		"id": "ricochet",
		"name": "跳弹寻的",
		"description": "主武器子弹命中后，有{ricochet_chance_value}%概率向最近敌人弹射。弹射在穿透前判定，成功则不消耗穿透次数",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "spread_shot",
		"name": "扇区弹幕",
		"description": "主武器弹道+{spread_shot_spread_value}，每发子弹造成{spread_shot_damage_ratio_value}%伤害",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "split_shot",
		"name": "破片分束",
		"description": "主武器暴击时，子弹分裂成{split_shot_count_value}发，每发造成50%伤害。仅在弹射失败时触发，不消耗穿透次数。分裂子弹无法再分裂",
		"quality": "red",
		"max_level": 2,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "breath_hold",
		"name": "蓄势待发",
		"description": "主武器未进行射击时，以+{breath_hold_rate_value}%/秒的速率给予暴击伤害加成。主武器射击后清空所有加成",
		"quality": "purple",
		"max_level": 10,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "focus",
		"name": "锁定集火",
		"description": "主武器连续命中同一敌人时，每发+{focus_crit_rate_value}%暴击率，最多叠加5层。未命中该敌人时重新计算",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "harvest",
		"name": "战场回收",
		"description": "暴击击杀敌人时，恢复{harvest_heal_value}点耐久",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "lethal_strike",
		"name": "终结射序",
		"description": "主武器每射击{lethal_strike_interval_value}次，下一次射击暴击率+100%，且暴击伤害翻倍",
		"quality": "red",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "crit_conversion",
		"name": "暴击溢流",
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
		"name": "反装甲触发雷",
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
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "cabin_ac",
		"name": "车载空调",
		"description": "回复耐久时，冷却速度 +{cabin_ac_value}%，持续3秒。不可叠加。",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "heat_sink",
		"name": "散热器",
		"description": "耐久上限 -{heat_sink_penalty_value}。耐久上限越低，全局冷却速度越快（+{heat_sink_cooling_desc}）",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "christie_suspension",
		"name": "克里斯蒂悬挂",
		"description": "移速 +{christie_suspension_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "gas_turbine",
		"name": "燃气轮机",
		"description": "移速 +{gas_turbine_value}%",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "hydro_pneumatic",
		"name": "液气悬挂",
		"description": "受到的移速惩罚减半",
		"quality": "purple",
		"max_level": 1,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "addon_armor",
		"name": "附加复合装甲",
		"description": "耐久 +{addon_armor_health_value}，被击穿时受到的伤害减免 {addon_armor_reduction_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "relief_valve",
		"name": "泄压阀",
		"description": "被击穿时受到的伤害减免 {relief_valve_value}%",
		"quality": "blue",
		"max_level": 6,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段四：配件系统扩展 ==========
	{
		"id": "smoke_grenade",
		"name": "多谱烟幕弹",
		"description": "原地释放烟雾，{smoke_radius_value}米范围内敌人移速 -{smoke_slow_value}%，持续{smoke_duration_value}秒。\n装填：10秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "radio_support",
		"name": "火力校射电台",
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
		"name": "防破片内衬",
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
		"name": "红外对抗套件",
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
	},
	# ========== 阶段八：新增通用强化 ==========
	{
		"id": "emergency_repair",
		"name": "应急抢修",
		"description": "耐久低于30%时，每5秒回复{emergency_repair_value}点耐久",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "reinforced_bulkhead",
		"name": "复合隔舱",
		"description": "受到致命伤害时保留1点耐久（每局可触发{reinforced_bulkhead_value}次）",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "kinetic_buffer",
		"name": "动能缓冲层",
		"description": "非击穿伤害减免{kinetic_buffer_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "overpressure_limiter",
		"name": "过压限制器",
		"description": "被连续命中时，后续2秒内受伤减少{overpressure_limiter_value}%",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "mobility_servos",
		"name": "伺服助力",
		"description": "转向响应 +{mobility_servos_turn_value}%，倒车速度 +{mobility_servos_reverse_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "target_computer",
		"name": "火控计算机",
		"description": "最近敌人方向偏差修正 +{target_computer_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "battle_awareness",
		"name": "战场感知",
		"description": "周围敌人越多，暴击率越高（上限 +{battle_awareness_value}%）",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段八：新增主武器通用强化 ==========
	{
		"id": "armor_breaker",
		"name": "破甲尖锥",
		"description": "对中重甲目标额外伤害 +{armor_breaker_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "weakpoint_strike",
		"name": "弱点标定",
		"description": "连续命中同目标后，第{weakpoint_strike_interval_value}发获得伤害加成",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "overdrive_trigger",
		"name": "超频扳机",
		"description": "满血时射速 +{overdrive_trigger_value}%，低血时伤害 +{overdrive_trigger_value}%",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "recoil_compensator",
		"name": "后坐补偿器",
		"description": "连续射击后散布不再继续扩大（散布上限 -{recoil_compensator_value}%）",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "tracer_rounds",
		"name": "曳光校正",
		"description": "子弹寿命 +{tracer_rounds_value}%，更易命中远端目标",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "shock_core",
		"name": "震荡芯体",
		"description": "命中时减速敌人{shock_core_value}秒",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "execution_protocol",
		"name": "处决协议",
		"description": "目标耐久低于20%时，额外伤害 +{execution_protocol_value}%",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "hot_load",
		"name": "高装药",
		"description": "弹速 +{hot_load_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "fin_stabilized",
		"name": "尾翼稳定器",
		"description": "弹道扩散角 -{fin_stabilized_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "sharpened",
		"name": "破片嵌入",
		"description": "暴击时附加{sharpened_value}层破片（对生物造成持续伤害）",
		"quality": "white",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "bloodletting",
		"name": "破片淬火",
		"description": "每层破片持续伤害 +{bloodletting_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "sharpened",
		"prefix": ""
	},
	{
		"id": "laceration",
		"name": "集束破片",
		"description": "破片层数上限提升{laceration_value}层并追加层数",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "sharpened",
		"prefix": ""
	},
	{
		"id": "kill_chain",
		"name": "杀戮链",
		"description": "连续5秒内有击杀时，全伤害 +{kill_chain_value}%（可刷新）",
		"quality": "red",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段八：新增配件 ==========
	{
		"id": "decoy_drone",
		"name": "诱饵无人机",
		"description": "周期生成诱饵吸引敌人{decoy_drone_duration_value}秒\n冷却：{decoy_drone_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "auto_turret",
		"name": "自主火力塔",
		"description": "部署火力塔自动射击最近敌人\n基础伤害：{auto_turret_damage_value}\n冷却：{auto_turret_cooldown_value}秒",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "repair_beacon",
		"name": "维修信标",
		"description": "放置信标，周围友军每秒回复{repair_beacon_heal_value}点耐久\n持续：{repair_beacon_duration_value}秒\n冷却：{repair_beacon_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "shield_emitter",
		"name": "相位护盾发生器",
		"description": "生成护盾吸收{shield_emitter_capacity_value}点伤害\n持续：{shield_emitter_duration_value}秒\n冷却：{shield_emitter_cooldown_value}秒",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "emp_pulse",
		"name": "EMP脉冲器",
		"description": "周期电磁脉冲，禁用范围内远程敌人瞄准{emp_pulse_duration_value}秒\n范围：{emp_pulse_radius_value}米\n冷却：{emp_pulse_cooldown_value}秒",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "grav_trap",
		"name": "引力陷阱",
		"description": "生成牵引场，将范围内敌人拉向中心\n范围：{grav_trap_radius_value}米\n持续：{grav_trap_duration_value}秒\n冷却：{grav_trap_cooldown_value}秒",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "thunder_coil",
		"name": "雷霆线圈",
		"description": "周期释放连锁电击，命中{thunder_coil_targets_value}个目标\n基础伤害：{thunder_coil_damage_value}\n冷却：{thunder_coil_cooldown_value}秒",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "cryo_canister",
		"name": "冷凝抑制器",
		"description": "投射冻结区域，减速并降低敌人攻速\n范围：{cryo_canister_radius_value}米\n持续：{cryo_canister_duration_value}秒\n冷却：{cryo_canister_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "incendiary_canister",
		"name": "温压投射器",
		"description": "投射燃烧区域，造成持续伤害\n基础伤害：{incendiary_canister_damage_value}/秒\n范围：{incendiary_canister_radius_value}米\n冷却：{incendiary_canister_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "acid_sprayer",
		"name": "酸蚀喷射器",
		"description": "锥形持续伤害并降低敌方护甲\n基础伤害：{acid_sprayer_damage_value}/秒\n冷却：{acid_sprayer_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "orbital_ping",
		"name": "轨道引导标",
		"description": "标记敌人后延时高伤单点打击\n基础伤害：{orbital_ping_damage_value}\n延迟：{orbital_ping_delay_value}秒\n冷却：{orbital_ping_cooldown_value}秒",
		"quality": "white",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "med_spray",
		"name": "纳米修复喷雾",
		"description": "周期释放修复喷雾，范围内每秒回复{med_spray_heal_value}点耐久\n范围：{med_spray_radius_value}米\n冷却：{med_spray_cooldown_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段九：新增配件 ==========
	{
		"id": "cluster_mine",
		"name": "集束地雷",
		"description": "部署集束地雷，延时爆炸并散布子雷\n基础伤害：{cluster_mine_damage_value}\n冷却：{cluster_mine_cooldown_value}秒",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "chaff_launcher",
		"name": "箔条发射器",
		"description": "释放箔条干扰，范围内远程敌人失去瞄准\n范围：{chaff_radius_value}米\n持续：{chaff_duration_value}秒\n冷却：{chaff_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "flare_dispenser",
		"name": "热焰干扰弹",
		"description": "释放热焰干扰弹，生成短时诱饵\n诱饵持续：{flare_duration_value}秒\n冷却：{flare_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "nano_armor",
		"name": "纳米装甲胶",
		"description": "周期修复耐久并生成临时护盾\n每次回复：{nano_armor_heal_value}点\n冷却：{nano_armor_cooldown_value}秒",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "fuel_injector_module",
		"name": "燃料增压模块",
		"description": "短时冲刺速度提升\n速度提升：{fuel_injector_speed_value}%\n持续：{fuel_injector_duration_value}秒\n冷却：{fuel_injector_cooldown_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "adrenaline_stim",
		"name": "肾上腺素针剂",
		"description": "低血量时触发兴奋，移速与射速提升\n触发血量：{adrenaline_stim_trigger_value}%\n持续：{adrenaline_stim_duration_value}秒",
		"quality": "white",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "sonar_scanner",
		"name": "声呐扫描器",
		"description": "周期标记周围敌人，标记目标受伤提高\n范围：{sonar_range_value}米\n持续：{sonar_duration_value}秒\n冷却：{sonar_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "ballistic_computer_pod",
		"name": "弹道计算吊舱",
		"description": "精确打击最近敌人\n基础伤害：{ballistic_damage_value}\n范围：{ballistic_radius_value}米\n冷却：{ballistic_cooldown_value}秒",
		"quality": "purple",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "jammer_field",
		"name": "干扰力场",
		"description": "干扰力场抑制远程敌人\n范围：{jammer_radius_value}米\n持续：{jammer_duration_value}秒\n冷却：{jammer_cooldown_value}秒",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "overwatch_uav",
		"name": "侦察无人机",
		"description": "侦察无人机持续投放小型炸弹\n基础伤害：{uav_damage_value}\n持续：{uav_duration_value}秒\n冷却：{uav_cooldown_value}秒",
		"quality": "purple",
		"max_level": 4,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "grapeshot_pod",
		"name": "霰雷吊舱",
		"description": "近距散射弹幕副武器\n基础伤害：{grapeshot_damage_value}\n冷却：{grapeshot_cooldown_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "scrap_collector",
		"name": "废料回收器",
		"description": "击杀概率回收修复碎片\n触发概率：{scrap_chance_value}%\n回复：{scrap_heal_value}点耐久",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	{
		"id": "kinetic_barrier",
		"name": "动能屏障",
		"description": "展开动能屏障减伤\n减伤：{barrier_reduction_value}%\n持续：{barrier_duration_value}秒\n冷却：{barrier_cooldown_value}秒",
		"quality": "red",
		"max_level": 3,
		"upgrade_type": "accessory",
		"exclusive_for": "",
		"prefix": ""
	},
	# ========== 阶段九：新增配件后置强化 ==========
	{
		"id": "cluster_count",
		"name": "集束地雷·子雷数量",
		"description": "子雷数量 +{cluster_count_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "cluster_mine",
		"prefix": ""
	},
	{
		"id": "cluster_radius",
		"name": "集束地雷·子雷范围",
		"description": "子雷爆炸范围 +{cluster_radius_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "cluster_mine",
		"prefix": ""
	},
	{
		"id": "chaff_density",
		"name": "箔条·覆盖密度",
		"description": "箔条影响范围 +{chaff_density_value}米",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "chaff_launcher",
		"prefix": ""
	},
	{
		"id": "chaff_duration",
		"name": "箔条·持续",
		"description": "箔条持续时间 +{chaff_duration_plus_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "chaff_launcher",
		"prefix": ""
	},
	{
		"id": "flare_count",
		"name": "热焰·数量",
		"description": "诱饵数量 +{flare_count_value}",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "flare_dispenser",
		"prefix": ""
	},
	{
		"id": "flare_cooldown",
		"name": "热焰·冷却",
		"description": "冷却速度 +{flare_cooldown_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "flare_dispenser",
		"prefix": ""
	},
	{
		"id": "nano_repair_rate",
		"name": "纳米装甲·修复速率",
		"description": "修复量 +{nano_repair_rate_value}点",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "nano_armor",
		"prefix": ""
	},
	{
		"id": "nano_overcap",
		"name": "纳米装甲·过量修复",
		"description": "修复后额外护盾 +{nano_overcap_value}点",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "nano_armor",
		"prefix": ""
	},
	{
		"id": "fuel_boost",
		"name": "燃料·增压",
		"description": "冲刺速度提升 +{fuel_boost_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "fuel_injector_module",
		"prefix": ""
	},
	{
		"id": "fuel_efficiency",
		"name": "燃料·效率",
		"description": "冷却速度 +{fuel_efficiency_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "fuel_injector_module",
		"prefix": ""
	},
	{
		"id": "stim_trigger_hp",
		"name": "兴奋·阈值",
		"description": "触发血量阈值 +{stim_trigger_hp_value}%",
		"quality": "white",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "adrenaline_stim",
		"prefix": ""
	},
	{
		"id": "stim_duration",
		"name": "兴奋·持续",
		"description": "持续时间 +{stim_duration_value}秒",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "adrenaline_stim",
		"prefix": ""
	},
	{
		"id": "sonar_range",
		"name": "声呐·范围",
		"description": "标记范围 +{sonar_range_bonus_value}米",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "sonar_scanner",
		"prefix": ""
	},
	{
		"id": "sonar_expose_bonus",
		"name": "声呐·暴露加成",
		"description": "标记伤害加成 +{sonar_expose_bonus_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "sonar_scanner",
		"prefix": ""
	},
	{
		"id": "ballistic_accuracy",
		"name": "弹道·精度",
		"description": "引导延迟 -{ballistic_accuracy_value}秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "ballistic_computer_pod",
		"prefix": ""
	},
	{
		"id": "ballistic_aoe",
		"name": "弹道·范围",
		"description": "爆炸范围 +{ballistic_aoe_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "ballistic_computer_pod",
		"prefix": ""
	},
	{
		"id": "jammer_radius",
		"name": "干扰·范围",
		"description": "干扰范围 +{jammer_radius_value}米",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "jammer_field",
		"prefix": ""
	},
	{
		"id": "jammer_intensity",
		"name": "干扰·强度",
		"description": "干扰持续 +{jammer_intensity_value}秒",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "jammer_field",
		"prefix": ""
	},
	{
		"id": "uav_bomb_rate",
		"name": "无人机·投弹频率",
		"description": "投弹间隔 -{uav_bomb_rate_value}秒",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "overwatch_uav",
		"prefix": ""
	},
	{
		"id": "uav_laser_tag",
		"name": "无人机·激光标记",
		"description": "投弹伤害 +{uav_laser_tag_value}%",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "overwatch_uav",
		"prefix": ""
	},
	{
		"id": "grapeshot_pellets",
		"name": "霰雷·弹丸数量",
		"description": "弹丸数量 +{grapeshot_pellets_value}",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "grapeshot_pod",
		"prefix": ""
	},
	{
		"id": "grapeshot_cone",
		"name": "霰雷·散射角",
		"description": "散射角 +{grapeshot_cone_value}°",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "grapeshot_pod",
		"prefix": ""
	},
	{
		"id": "scrap_drop_rate",
		"name": "回收·掉落率",
		"description": "掉落概率 +{scrap_drop_rate_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "scrap_collector",
		"prefix": ""
	},
	{
		"id": "scrap_value",
		"name": "回收·价值",
		"description": "回复量 +{scrap_value_value}点",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "scrap_collector",
		"prefix": ""
	},
	{
		"id": "barrier_angle",
		"name": "屏障·持续",
		"description": "屏障持续 +{barrier_angle_value}秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "kinetic_barrier",
		"prefix": ""
	},
	{
		"id": "barrier_reflect",
		"name": "屏障·反弹",
		"description": "减伤效果 +{barrier_reflect_value}%",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "kinetic_barrier",
		"prefix": ""
	},
	# ========== 阶段九：旧配件后置强化补齐 ==========
	{
		"id": "cooling_share",
		"name": "冷却装置·共享",
		"description": "冷却速度 +{cooling_share_value}%",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "cooling_device",
		"prefix": ""
	},
	{
		"id": "cooling_safeguard",
		"name": "冷却装置·安全冗余",
		"description": "冷却速度 +{cooling_safeguard_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "cooling_device",
		"prefix": ""
	},
	{
		"id": "radio_barrage_count",
		"name": "无线电·多轮轰炸",
		"description": "炮击次数 +{radio_barrage_count_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "radio_support",
		"prefix": ""
	},
	{
		"id": "laser_focus",
		"name": "激光·聚焦",
		"description": "射程 +{laser_focus_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "laser_suppress",
		"prefix": ""
	},
	{
		"id": "laser_overheat_cut",
		"name": "激光·散热优化",
		"description": "冷却速度 +{laser_overheat_cut_value}%",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "laser_suppress",
		"prefix": ""
	},
	{
		"id": "spall_reload",
		"name": "纤维内衬·复位",
		"description": "复位间隔 -{spall_reload_value}秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "spall_liner",
		"prefix": ""
	},
	{
		"id": "spall_reserve",
		"name": "纤维内衬·储备",
		"description": "额外次数 +{spall_reserve_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "spall_liner",
		"prefix": ""
	},
	{
		"id": "era_rearm",
		"name": "爆反·再装填",
		"description": "复位间隔 -{era_rearm_value}秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "era_block",
		"prefix": ""
	},
	{
		"id": "era_shockwave",
		"name": "爆反·冲击波",
		"description": "触发时冲击伤害 +{era_shockwave_value}",
		"quality": "purple",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "era_block",
		"prefix": ""
	},
	{
		"id": "missile_warhead",
		"name": "导弹·战斗部",
		"description": "爆炸范围 +{missile_warhead_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "external_missile",
		"prefix": ""
	},
	{
		"id": "ir_wideband",
		"name": "红外·宽带",
		"description": "作用范围 +{ir_wideband_value}米",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "ir_counter",
		"prefix": ""
	},
	{
		"id": "ir_lockbreak",
		"name": "红外·锁定干扰",
		"description": "干扰持续 +{ir_lockbreak_value}秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "ir_counter",
		"prefix": ""
	},
	{
		"id": "decoy_duration",
		"name": "诱饵·持续",
		"description": "持续时间 +{decoy_duration_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "decoy_drone",
		"prefix": ""
	},
	{
		"id": "decoy_count",
		"name": "诱饵·数量",
		"description": "诱饵数量 +{decoy_count_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "decoy_drone",
		"prefix": ""
	},
	{
		"id": "turret_rate",
		"name": "炮塔·射速",
		"description": "射速 +{turret_rate_value}",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "auto_turret",
		"prefix": ""
	},
	{
		"id": "turret_pierce",
		"name": "炮塔·穿深",
		"description": "伤害 +{turret_pierce_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "auto_turret",
		"prefix": ""
	},
	{
		"id": "emp_duration",
		"name": "EMP·持续",
		"description": "禁用时间 +{emp_duration_value}秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "emp_pulse",
		"prefix": ""
	},
	{
		"id": "emp_radius",
		"name": "EMP·范围",
		"description": "范围 +{emp_radius_value}米",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "emp_pulse",
		"prefix": ""
	},
	{
		"id": "beacon_heal",
		"name": "信标·回复",
		"description": "回复量 +{beacon_heal_value}",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "repair_beacon",
		"prefix": ""
	},
	{
		"id": "beacon_uptime",
		"name": "信标·持续",
		"description": "持续时间 +{beacon_uptime_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "repair_beacon",
		"prefix": ""
	},
	{
		"id": "shield_capacity",
		"name": "护盾·容量",
		"description": "护盾容量 +{shield_capacity_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "shield_emitter",
		"prefix": ""
	},
	{
		"id": "shield_regen",
		"name": "护盾·回充",
		"description": "护盾回复 +{shield_regen_value}/秒",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "shield_emitter",
		"prefix": ""
	},
	{
		"id": "coil_chain_count",
		"name": "线圈·链数",
		"description": "连锁目标 +{coil_chain_count_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "thunder_coil",
		"prefix": ""
	},
	{
		"id": "coil_damage",
		"name": "线圈·增伤",
		"description": "伤害 +{coil_damage_value}",
		"quality": "blue",
		"max_level": 3,
		"upgrade_type": "enhancement",
		"exclusive_for": "thunder_coil",
		"prefix": ""
	},
	{
		"id": "cryo_slow",
		"name": "冷凝·减速",
		"description": "减速强度 +{cryo_slow_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "cryo_canister",
		"prefix": ""
	},
	{
		"id": "cryo_duration",
		"name": "冷凝·持续",
		"description": "减速持续 +{cryo_duration_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "cryo_canister",
		"prefix": ""
	},
	{
		"id": "fire_duration",
		"name": "燃烧·持续",
		"description": "燃烧持续 +{fire_duration_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "incendiary_canister",
		"prefix": ""
	},
	{
		"id": "fire_damage",
		"name": "燃烧·增伤",
		"description": "燃烧伤害 +{fire_damage_value}/秒",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "incendiary_canister",
		"prefix": ""
	},
	{
		"id": "acid_armor_break",
		"name": "酸蚀·破甲",
		"description": "伤害加成 +{acid_armor_break_value}%",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "acid_sprayer",
		"prefix": ""
	},
	{
		"id": "acid_spread",
		"name": "酸蚀·扩散",
		"description": "喷射角度 +{acid_spread_value}°",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "acid_sprayer",
		"prefix": ""
	},
	{
		"id": "orbital_delay_cut",
		"name": "轨道·延迟缩短",
		"description": "延迟 -{orbital_delay_cut_value}秒",
		"quality": "white",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "orbital_ping",
		"prefix": ""
	},
	{
		"id": "orbital_damage",
		"name": "轨道·增伤",
		"description": "伤害 +{orbital_damage_value}",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "orbital_ping",
		"prefix": ""
	},
	{
		"id": "med_tick_rate",
		"name": "喷雾·频率",
		"description": "治疗间隔 -{med_tick_rate_value}秒",
		"quality": "white",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "med_spray",
		"prefix": ""
	},
	{
		"id": "med_radius",
		"name": "喷雾·范围",
		"description": "范围 +{med_radius_value}米",
		"quality": "blue",
		"max_level": 5,
		"upgrade_type": "enhancement",
		"exclusive_for": "med_spray",
		"prefix": ""
	},
	{
		"id": "grav_pull",
		"name": "引力·牵引",
		"description": "牵引力 +{grav_pull_value}",
		"quality": "blue",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "grav_trap",
		"prefix": ""
	},
	{
		"id": "grav_duration",
		"name": "引力·持续",
		"description": "持续时间 +{grav_duration_value}秒",
		"quality": "white",
		"max_level": 4,
		"upgrade_type": "enhancement",
		"exclusive_for": "grav_trap",
		"prefix": ""
	}
]

# 升级图标映射：在编辑器中为每个升级配置对应的图标
@export var upgrade_icons: Dictionary = {
	"addon_armor": preload("res://Assets/Upgrades/addon_armor.png"),
	"battle_awareness": preload("res://Assets/Upgrades/battle_awareness.png"),
	"breakthrough": preload("res://Assets/Upgrades/breakthrough.png"),
	"breath_hold": preload("res://Assets/Upgrades/breath_hold.png"),
	"burst_fire": preload("res://Assets/Upgrades/burst_fire.png"),
	"cabin_ac": preload("res://Assets/Upgrades/cabin_ac.png"),
	"chain_fire": preload("res://Assets/Upgrades/chain_fire.png"),
	"chaos_fire": preload("res://Assets/Upgrades/chaos_fire.png"),
	"christie_suspension": preload("res://Assets/Upgrades/christie_suspension.png"),
	"crit_damage": preload("res://Assets/Upgrades/crit_damage.png"),
	"crit_rate": preload("res://Assets/Upgrades/crit_rate.png"),
	"damage_bonus": preload("res://Assets/Upgrades/damage_bonus.png"),
	"emergency_repair": preload("res://Assets/Upgrades/emergency_repair.png"),
	"external_missile": preload("res://Assets/Upgrades/external_missile_icon.png"),
	"external_missile_icon": preload("res://Assets/Upgrades/external_missile_icon.png"),
	"extra_ammo_rack": preload("res://Assets/Upgrades/extra_ammo_rack.png"),
	"fire_suppression": preload("res://Assets/Upgrades/fire_suppression.png"),
	"focus": preload("res://Assets/Upgrades/focus.png"),
	"gas_turbine": preload("res://Assets/Upgrades/gas_turbine.png"),
	"heat_sink": preload("res://Assets/Upgrades/heat_sink.png"),
	"health": preload("res://Assets/Upgrades/health.png"),
	"hydro_pneumatic": preload("res://Assets/Upgrades/hydro_pneumatic.png"),
	"kinetic_buffer": preload("res://Assets/Upgrades/kinetic_buffer.png"),
	"laser_rangefinder": preload("res://Assets/Upgrades/laser_rangefinder.png"),
	"long_barrel": preload("res://Assets/Upgrades/long_barrel.png"),
	"mine": preload("res://Assets/GPT/ChatGPT mine.png"),
	"mobility_servos": preload("res://Assets/Upgrades/mobility_servos.png"),
	"penetration": preload("res://Assets/Upgrades/penetration.png"),
	"rapid_fire": preload("res://Assets/Upgrades/rapid_fire.png"),
	"reinforced_bulkhead": preload("res://Assets/Upgrades/reinforced_bulkhead.png"),
	"relief_valve": preload("res://Assets/Upgrades/relief_valve.png"),
	"repair_kit": preload("res://Assets/Upgrades/repair_kit.png"),
	"ricochet": preload("res://Assets/Upgrades/ricochet.png"),
	"sap_round": preload("res://Assets/Upgrades/sap_round.png"),
	"scatter_shot": preload("res://Assets/Upgrades/scatter_shot.png"),
	"split_shot": preload("res://Assets/Upgrades/split_shot.png"),
	"spread_shot": preload("res://Assets/Upgrades/spread_shot.png"),
	"sweep_fire": preload("res://Assets/Upgrades/sweep_fire.png"),
	"tandem_heat": preload("res://Assets/Upgrades/tandem_heat.png"),
	"target_computer": preload("res://Assets/Upgrades/target_computer.png"),
	"thermal_imager": preload("res://Assets/Upgrades/thermal_imager.png"),
	"thunder_coil": preload("res://Assets/Upgrades/thunder_coil_icon.png"),
	"thunder_coil_icon": preload("res://Assets/Upgrades/thunder_coil_icon.png"),
	"windmill": preload("res://Assets/Upgrades/windmill.png"),
}

func get_entry(upgrade_id):
	for entry in entries:
		if entry.get("id") == upgrade_id:
			return entry
	return null

func get_icon(upgrade_id: String) -> Texture2D:
	"""获取升级对应的图标"""
	return upgrade_icons.get(upgrade_id, null)
