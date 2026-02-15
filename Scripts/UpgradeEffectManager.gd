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
	
	# ========== 其他主武器专属强化 ==========
	
	# 榴弹炮·装填：每级 +10%（射速加成）
	"howitzer_reload": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	
	# 榴弹炮·爆炸半径：每级 +0.5米
	"howitzer_radius": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	
	# 坦克炮·穿深：每级 +2mm
	"tank_gun_depth": {
		"type": "linear",
		"per_level_value": 2.0,
		"max_level": 5
	},
	
	# 坦克炮·穿透：每级 +1
	"tank_gun_penetration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 导弹·齐射：每级 +1 枚
	"missile_salvo": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# 导弹·装填：每级 +10%（射速加成）
	"missile_reload": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
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
	},

	# ========== 阶段三：通用生存/机动/防御 ==========

	# 维护工具箱：冷却间隔由表给出，等级 1~9 对应 15/12/10/9/8/7/6/5/4 秒
	"repair_kit": {
		"type": "custom",
		"level_effects": {
			1: 15.0, 2: 12.0, 3: 10.0, 4: 9.0, 5: 8.0, 6: 7.0, 7: 6.0, 8: 5.0, 9: 4.0
		}
	},

	# 车载空调：回复耐久时冷却速度 +5%*等级，持续3秒
	"cabin_ac": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 5
	},

	# 散热器：耐久上限 -5*等级；冷却速度 = (初始耐久上限-当前耐久上限)*0.1*等级%（在玩家逻辑中计算）
	"heat_sink": {
		"type": "linear",
		"per_level_value": 5.0,
		"max_level": 5
	},

	# 克里斯蒂悬挂：移速 +10%*等级
	"christie_suspension": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},

	# 燃气轮机：移速 +15%*等级
	"gas_turbine": {
		"type": "linear",
		"per_level_value": 0.15,
		"max_level": 3
	},

	# 液气悬挂：移速惩罚减半，唯一
	"hydro_pneumatic": {
		"type": "custom",
		"level_effects": { 1: 1.0 }
	},

	# 车身附加装甲：耐久 +4*等级，被击穿时伤害减免 5%*等级（pierce_reduction_per_level 供击穿减伤逻辑读取）
	"addon_armor": {
		"type": "linear",
		"per_level_value": 4.0,
		"max_level": 5,
		"pierce_reduction_per_level": 0.05
	},

	# 泄压阀：被击穿时伤害减免 10%*等级
	"relief_valve": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 6
	},

	# ========== 阶段四：配件系统扩展 ==========

	# 烟雾弹：等级用于强度/解锁（数值在控制器中按公式处理）
	"smoke_grenade": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	# 烟雾弹·范围：+2m/级
	"smoke_range": {
		"type": "linear",
		"per_level_value": 2.0,
		"max_level": 5
	},
	# 烟雾弹·持续：+1s/级
	"smoke_duration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 无线电通讯：基础伤害=50+20lv（用于 UI/控制器取值）
	"radio_support": {
		"type": "custom",
		"level_effects": { 1: 70.0, 2: 90.0, 3: 110.0 },
		"max_level": 3
	},
	# 无线电·半径：+1m/级
	"radio_radius": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 激光压制：基础伤害=4+2lv（每次命中伤害）
	"laser_suppress": {
		"type": "custom",
		"level_effects": { 1: 6.0, 2: 8.0, 3: 10.0 },
		"max_level": 3
	},

	# 外挂导弹：基础伤害=20+10lv
	"external_missile": {
		"type": "custom",
		"level_effects": { 1: 30.0, 2: 40.0, 3: 50.0 },
		"max_level": 3
	},
	# 外挂导弹·伤害：+25%/级
	"missile_damage": {
		"type": "linear",
		"per_level_value": 0.25,
		"max_level": 5
	},

	# 纤维内衬：唯一（逻辑在 player.gd 中处理）
	"spall_liner": {
		"type": "custom",
		"level_effects": { 1: 1.0 },
		"max_level": 1
	},
	# 爆炸反应装甲：唯一（逻辑在 player.gd 中处理）
	"era_block": {
		"type": "custom",
		"level_effects": { 1: 1.0 },
		"max_level": 1
	},
	# 红外对抗：唯一（逻辑在 player.gd 中处理）
	"ir_counter": {
		"type": "custom",
		"level_effects": { 1: 1.0 },
		"max_level": 1
	},

	# ========== 阶段八：新增通用强化 ==========

	# 应急抢修：每级回复 1+lv 点（低于30%耐久时每5秒触发）
	"emergency_repair": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 复合隔舱：免死次数 = 1+lv
	"reinforced_bulkhead": {
		"type": "custom",
		"level_effects": { 1: 2.0, 2: 3.0, 3: 4.0 },
		"max_level": 3
	},

	# 动能缓冲层：非击穿伤害减免 6%*lv
	"kinetic_buffer": {
		"type": "linear",
		"per_level_value": 0.06,
		"max_level": 5
	},

	# 过压限制器：被连续命中后2秒内受伤 -8%*lv
	"overpressure_limiter": {
		"type": "linear",
		"per_level_value": 0.08,
		"max_level": 4
	},

	# 伺服助力：转向响应 +12%*lv（倒车速度在 player 中处理）
	"mobility_servos": {
		"type": "linear",
		"per_level_value": 0.12,
		"max_level": 5
	},

	# 火控计算机：方向偏差修正 +10%*lv
	"target_computer": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},

	# 战场感知：每级上限 +2% 暴击率
	"battle_awareness": {
		"type": "linear",
		"per_level_value": 0.02,
		"max_level": 5
	},

	# ========== 阶段八：新增主武器通用强化 ==========

	# 破甲尖锥：对中重甲额外伤害 +8%*lv
	"armor_breaker": {
		"type": "linear",
		"per_level_value": 0.08,
		"max_level": 5
	},

	# 弱点标定：连续命中后第 N 发加成（N 随等级递减）
	"weakpoint_strike": {
		"type": "custom",
		"level_effects": { 1: 4.0, 2: 3.0, 3: 3.0, 4: 2.0, 5: 2.0 },
		"max_level": 5
	},

	# 超频扳机：满血射速 or 低血伤害 +7%*lv
	"overdrive_trigger": {
		"type": "linear",
		"per_level_value": 0.07,
		"max_level": 5
	},

	# 后坐补偿器：连射散布上限 -20%*lv
	"recoil_compensator": {
		"type": "linear",
		"per_level_value": 0.20,
		"max_level": 5
	},

	# 曳光校正：子弹寿命 +10%*lv
	"tracer_rounds": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},

	# 震荡芯体：命中减速 0.4*lv 秒
	"shock_core": {
		"type": "linear",
		"per_level_value": 0.4,
		"max_level": 5
	},

	# 处决协议：目标低于20%耐久时额外 +6%*lv 伤害
	"execution_protocol": {
		"type": "linear",
		"per_level_value": 0.06,
		"max_level": 5
	},

	# 高装药：弹速 +10%*lv
	"hot_load": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},

	# 尾翼稳定器：弹道扩散角 -20%*lv
	"fin_stabilized": {
		"type": "linear",
		"per_level_value": 0.20,
		"max_level": 5
	},

	# 破片嵌入：每级 +1 层破片
	"sharpened": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},

	# 破片淬火：每层破片伤害 +0.2*lv
	"bloodletting": {
		"type": "linear",
		"per_level_value": 0.2,
		"max_level": 5
	},

	# 集束破片：每级提升破片上限 +1 并追加 1 层
	"laceration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 杀戮链：连续击杀期间全伤害 +6%*lv
	"kill_chain": {
		"type": "linear",
		"per_level_value": 0.06,
		"max_level": 5
	},

	# ========== 阶段八：新增配件 ==========

	# 诱饵无人机
	"decoy_drone": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 自主火力塔
	"auto_turret": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 维修信标
	"repair_beacon": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 相位护盾发生器
	"shield_emitter": {
		"type": "custom",
		"level_effects": { 1: 30.0, 2: 50.0, 3: 75.0 },
		"max_level": 3
	},

	# EMP脉冲器
	"emp_pulse": {
		"type": "custom",
		"level_effects": { 1: 3.0, 2: 4.0, 3: 5.0 },
		"max_level": 3
	},

	# 引力陷阱
	"grav_trap": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},

	# 雷霆线圈
	"thunder_coil": {
		"type": "custom",
		"level_effects": { 1: 15.0, 2: 25.0, 3: 40.0 },
		"max_level": 3
	},

	# 冷凝抑制器
	"cryo_canister": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 温压投射器
	"incendiary_canister": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 酸蚀喷射器
	"acid_sprayer": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},

	# 轨道引导标
	"orbital_ping": {
		"type": "custom",
		"level_effects": { 1: 80.0, 2: 120.0, 3: 160.0, 4: 200.0 },
		"max_level": 4
	},

	# 纳米修复喷雾
	"med_spray": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	
	# ========== 阶段九：新增配件 ==========
	"cluster_mine": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"chaff_launcher": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"flare_dispenser": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"nano_armor": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	"fuel_injector_module": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"adrenaline_stim": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	"sonar_scanner": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"ballistic_computer_pod": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"jammer_field": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	"overwatch_uav": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
	},
	"grapeshot_pod": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"scrap_collector": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"kinetic_barrier": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	
	# ========== 阶段九：新增配件后置强化 ==========
	"cluster_count": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"cluster_radius": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"chaff_density": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"chaff_duration": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"flare_count": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"flare_cooldown": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"nano_repair_rate": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"nano_overcap": {
		"type": "linear",
		"per_level_value": 2.0,
		"max_level": 3
	},
	"fuel_boost": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"fuel_efficiency": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"stim_trigger_hp": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 4
	},
	"stim_duration": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 4
	},
	"sonar_range": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"sonar_expose_bonus": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 5
	},
	"ballistic_accuracy": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"ballistic_aoe": {
		"type": "linear",
		"per_level_value": 0.2,
		"max_level": 5
	},
	"jammer_radius": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 4
	},
	"jammer_intensity": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 4
	},
	"uav_bomb_rate": {
		"type": "linear",
		"per_level_value": 0.15,
		"max_level": 4
	},
	"uav_laser_tag": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 4
	},
	"grapeshot_pellets": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"grapeshot_cone": {
		"type": "linear",
		"per_level_value": 5.0,
		"max_level": 5
	},
	"scrap_drop_rate": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 5
	},
	"scrap_value": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"barrier_angle": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 3
	},
	"barrier_reflect": {
		"type": "linear",
		"per_level_value": 0.08,
		"max_level": 3
	},
	
	# ========== 阶段九：旧配件后置强化补齐 ==========
	"cooling_share": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 3
	},
	"cooling_safeguard": {
		"type": "linear",
		"per_level_value": 0.03,
		"max_level": 5
	},
	"radio_barrage_count": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"laser_focus": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"laser_overheat_cut": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"spall_reload": {
		"type": "linear",
		"per_level_value": 5.0,
		"max_level": 3
	},
	"spall_reserve": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"era_rearm": {
		"type": "linear",
		"per_level_value": 6.0,
		"max_level": 3
	},
	"era_shockwave": {
		"type": "linear",
		"per_level_value": 6.0,
		"max_level": 3
	},
	"missile_warhead": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"ir_wideband": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"ir_lockbreak": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 3
	},
	"decoy_duration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"decoy_count": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"turret_rate": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"turret_pierce": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"emp_duration": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 3
	},
	"emp_radius": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 3
	},
	"beacon_heal": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"beacon_uptime": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"shield_capacity": {
		"type": "linear",
		"per_level_value": 10.0,
		"max_level": 3
	},
	"shield_regen": {
		"type": "linear",
		"per_level_value": 2.0,
		"max_level": 3
	},
	"coil_chain_count": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 3
	},
	"coil_damage": {
		"type": "linear",
		"per_level_value": 5.0,
		"max_level": 3
	},
	"cryo_slow": {
		"type": "linear",
		"per_level_value": 0.05,
		"max_level": 5
	},
	"cryo_duration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"fire_duration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"fire_damage": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 5
	},
	"acid_armor_break": {
		"type": "linear",
		"per_level_value": 0.08,
		"max_level": 5
	},
	"acid_spread": {
		"type": "linear",
		"per_level_value": 5.0,
		"max_level": 5
	},
	"orbital_delay_cut": {
		"type": "linear",
		"per_level_value": 0.3,
		"max_level": 4
	},
	"orbital_damage": {
		"type": "linear",
		"per_level_value": 20.0,
		"max_level": 4
	},
	"med_tick_rate": {
		"type": "linear",
		"per_level_value": 0.10,
		"max_level": 5
	},
	"med_radius": {
		"type": "linear",
		"per_level_value": 0.5,
		"max_level": 5
	},
	"grav_pull": {
		"type": "linear",
		"per_level_value": 20.0,
		"max_level": 4
	},
	"grav_duration": {
		"type": "linear",
		"per_level_value": 1.0,
		"max_level": 4
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
			var result = float(level) * per_level_value
			if upgrade_id == "cooling_device":
				var share_level = GameManager.current_upgrades.get("cooling_share", {}).get("level", 0)
				var safeguard_level = GameManager.current_upgrades.get("cooling_safeguard", {}).get("level", 0)
				if share_level > 0:
					result += get_effect("cooling_share", share_level)
				if safeguard_level > 0:
					result += get_effect("cooling_safeguard", safeguard_level)
			return result
		
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
