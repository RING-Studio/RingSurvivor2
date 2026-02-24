# 交接文档 — 供下次对话使用

更新日期：2026-02-19（阶段16-D：配件预升级 + Bug修复 + QoL改进）

## 如何使用本文档
在新的对话开始时，请 AI 阅读以下文件以快速恢复上下文：
1. **本文档**：`DOCUMENTS/HANDOFFS/HANDOFF.md`（当前进度摘要）
2. **策划书**：`DOCUMENTS/策划书v2.md`（游戏设计全貌）
3. **ROADMAP**：`DOCUMENTS/ROADMAP.md`（开发进度与规划）
4. **注意事项**：`DOCUMENTS/注意事项.md`（编码规范）
5. **关卡设计**：`DOCUMENTS/关卡.md`（敌人/关卡/目标系统详细设计）
6. **Cursor 规则**：`.cursor/rules/gdscript-coding-standards.mdc`（自动应用的编码规范）

## 项目概述
- **引擎**：Godot 4.5.1 (GDScript)
- **类型**：类幸存者 Roguelike + AVG + 基地经营
- **背景**：沙漠末世，军营绿洲小城，驾驶改装车辆在污染区执行任务

## 当前完成状态（截至 2026-02-19）

### 核心系统已实现
- **升级系统**：Roguelike 单局升级池（白/蓝/紫/红品质）、配件+强化、互斥升级
  - **阶段15扩充已全部完成**：17个新升级，含stat类+9个复杂运行时机制
- **武器系统**：机炮（主武器）+ 多种配件能力（地雷、榴弹、导弹等 30+种）
  - **机炮全局伤害加成已修复**（阶段16-A）：`_compute_damage_against()` 已切换为 `get_damage_modifier()`
- **战斗系统**：装甲/覆甲/穿透管线、暴击、击退、减速、冲击波等
  - **WeaponUpgradeHandler** 作为中央武器升级处理器，管理射速/伤害/暴击/穿透修正
  - 新增回调：`on_non_crit_hit()`、`on_weapon_miss()`、`check_multi_feed()`
  - 新增 getter：`get_precision_bore_depth_bonus()`、`get_shock_fragment_damage()`
  - 新增内部方法：`_spawn_detonation_explosion()`
- **敌人系统**：6 种小怪 + 2 种 Boss（沙漠/污染主题），EnemyRank 枚举
- **关卡系统**：
  - `MissionData.gd`：纯数据表（8 个关卡 + 6 个目的地），objectives 仅含显示信息
  - `ObjectiveManager`：关卡场景树子节点，管理目标逻辑/进度/触发链
  - `ObjectiveHUD`：关卡场景树子节点，显示目标 HUD
  - `MissionMap`：军营覆盖层地图场景（替代旧 MissionSelectPanel）
  - **4 个独立关卡场景**：LevelDesert、LevelContaminated、LevelBoss、LevelTest
- **章节系统**（阶段14.3/14.4 已完成）：
  - `CHAPTER_DEFINITIONS` 定义 3 个章节，每章含必须通关任务、奖励、NPC解锁
  - `check_chapter_completion()` 任务通关后自动检测章节完成
  - `_complete_chapter()` 发放金币/素材奖励 + 解锁下一章 + 推进NPC对话
  - `_check_story_progression()` 目标完成时自动检查剧情推进
  - `get_progression_summary()` 提供进度摘要供UI使用
- **NPC 对话系统**（阶段14 + 阶段16-C 扩展）：
  - `DialogueRunner` autoload：overlay/fullscreen 两种模式
  - NPC 对话进度追踪（`GameManager.npc_dialogues`）
  - 章节完成自动推进NPC对话索引
  - **2 个 NPC**：机械师（4 段对话）+ 军需官（5 段对话）
- **收集物系统**（阶段12新增）：
  - `Collectible` 实体：磁吸拾取、全局信号、可配置类型/颜色
  - `CollectibleDropComponent`：挂在敌人上，按概率/类型过滤掉落
- **防守据点**（阶段12新增）：
  - `DefendOutpost` 实体：有 HP、血条、敌人接近造成伤害、毁坏信号
- **存档系统**：SaveData（不考虑存档兼容），已含 `materials` 素材库字段
- **章节进度 UI**（阶段16-A 完成）：
  - `ProgressionHUD`（`scenes/ui/progression_hud.gd`）：军营常驻 CanvasLayer 面板
  - 显示当前章节名称、任务通关数/总数、逐章节任务完成详情
  - 可折叠切换（右上角按钮），任务地图/NPC对话时自动隐藏
  - 数据源：`GameManager.get_progression_summary()` + `CHAPTER_DEFINITIONS`
- **配装出击费用系统**（阶段16-B Mark E.2 完成）：
  - `EquipmentCostData.gd`：装备出击费用表（主武器/配件分 4 个费用层级）
  - `GameManager` 新增：`get_total_sortie_cost()`、`can_afford_sortie()`、`deduct_sortie_cost()`
  - `MissionMap`：任务详情面板显示出击费用及资源余额，资源不足时禁止出击
  - `MilitaryCamp`：出击时自动扣除费用
  - `CarEditor/ListDisplay`：装备详情显示出击费用
  - `DebugConsole`：`cost` 命令查看当前配装出击费用
- **目标奖励系统**（阶段16-C 新增）：
  - 每个关卡脚本定义 `_get_victory_bonus()` 基础通关奖励 + `_get_objective_rewards()` 次要目标奖励
  - `_build_settlement()` 自动处理并发放奖励（金币+素材，不受损失比例影响）
  - `end_screen.gd` 显示通关奖励和各次要目标奖励详情
  - `MissionData.reward_preview` 与实际奖励对齐
- **配件预升级系统**（阶段16-D Mark E.3 完成）：
  - 已装备配件可在车辆编辑器中预升级（Lv.1~3）
  - 预升级费用在出击时结算：Lv2 = 基础 + 50%金币 + 1×素材，Lv3 = 基础 + 100%金币 + 2×素材
  - 局内带入配件按预升级等级初始化
  - 卸载配件时自动重置等级
  - `EquipmentCostData.get_accessory_total_cost()` 计算等级费用
  - `ListDisplay` 显示预升级控件和等级调整后费用
  - Debug 命令：`acclv <id> <lv>` 设置配件预升级等级
- **任务地图增强**（阶段16-D QoL）：
  - 通关奖励预览（`reward_preview` 字段）显示在任务详情中
  - 未解锁任务显示解锁条件（从 `unlock_condition` 解析为可读文本）
  - 未解锁任务仍可点击查看信息（灰色显示，不可出击）
- **进度面板增强**（阶段16-D QoL）：
  - `ProgressionHUD` 新增资源一览区域（金币 + 所有素材）
- **DebugConsole 全局控制台**（autoload）
- **BaseLevel 基类**
- **结算与带出物品系统**（Mark C 完成）
- **配件解锁系统**（Mark E.1 完成）
- **实体场景化**（Mark S 完成）
- **代码健康度清理**（Mark D 完成）

### 阶段16-C 目标奖励系统实现细节

#### 通关奖励（victory_bonus）
| 关卡 ID | 金币 | 素材 |
|---------|------|------|
| recon_patrol | 200 | — |
| salvage_run | 260 | — |
| containment | 300 | — |
| extermination | 320 | — |
| outpost_defense | 350 | — |
| high_risk_sweep | 500 | — |
| titan_hunt | 400 | scrap_metal ×1 |
| hive_assault | 450 | bio_sample ×2 |

#### 次要目标奖励（objective_rewards）
| 关卡 ID | 目标 | 金币 | 素材 |
|---------|------|------|------|
| recon_patrol | 击杀 60 只敌人 | 100 | — |
| salvage_run | 击杀 100 只敌人 | 150 | scrap_metal ×1 |
| containment | 击杀 15 只精英 | 200 | bio_sample ×2 |
| extermination | 击杀 10 只精英 | 180 | — |
| outpost_defense | 据点血量 >50% | 250 | energy_core ×1 |
| high_risk_sweep | 击杀 25 只精英 | 300 | acid_gland ×2 |
| titan_hunt | 120秒内击杀巨兽 | 300 | scarab_chitin ×2 |
| hive_assault | 击杀 30 膨爆蜱 | 150 | — |
| hive_assault | 收集 10 生物样本 | 200 | spore_sample ×1 |

#### 军需官 NPC（阶段16-C 新增）
- NPC ID：`npc_quartermaster`
- 对话数据：`DialogueData/Dialogue3.dialogue`（5 段对话：intro → day2 → day3 → day4 → idle）
- 场景位置：MilitaryCamp 建筑节点 `npc_quartermaster`
- 章节解锁推进：第一章→day2，第二章→day3，第三章→day4
- 对话内容主题：资源管理、出击费用、任务奖励提示

### 阶段15 运行时机制升级实现细节
| 升级 ID | 实现位置 | 机制 |
|---------|----------|------|
| `suppressive_net` | WeaponUpgradeHandler.on_weapon_hit | 500ms窗口3+命中 → 3秒射速加成 |
| `stable_platform` | WeaponUpgradeHandler.get_damage_modifier | 移动时伤害+8%*lv |
| `multi_feed` | mg_controller.on_timer_timeout + WUH.check_multi_feed | 概率免费额外射击 |
| `precision_bore` | 各弹体脚本暴击分支 + WUH.get_precision_bore_depth_bonus | 暴击时穿深转伤害 |
| `detonation_link` | WUH.on_enemy_killed_by_critical → _spawn_detonation_explosion | 暴击击杀60px AoE |
| `shock_fragment` | 各弹体命中后 + WUH.get_shock_fragment_damage | 穿透后附加破片伤害 |
| `fallback_firing` | 弹体._on_lifetime_expired → WUH.on_weapon_miss | 未命中积累加成 |
| `thermal_bolt` | WUH.on_weapon_critical + on_non_crit_hit | 暴击+1层/非暴击-1层，层×射速 |
| `breach_equip` | player.gd.on_body_entered | 碰撞伤害=速度×耐久×系数 |

### 阶段16-B Mark E.2 配装出击费用实现细节
| 费用层级 | money | 素材 | 适用装备 |
|---------|-------|------|---------|
| Tier 1 | 100 | — | mine, smoke_grenade, spall_liner, era_block, ir_counter, scrap_collector, cooling_device |
| Tier 2 | 200 | — | decoy_drone, chaff_launcher, flare_dispenser, nano_armor, med_spray, kinetic_barrier, fuel_injector_module, adrenaline_stim |
| Tier 3 | 400 | scrap_metal ×1 | radio_support, laser_suppress, external_missile, cluster_mine, repair_beacon, cryo_canister, incendiary_canister, acid_sprayer, grav_trap, grapeshot_pod |
| Tier 4 | 600 | scrap_metal/energy_core ×2 | auto_turret, emp_pulse, shield_emitter, thunder_coil, orbital_ping, ballistic_computer_pod, jammer_field, overwatch_uav, sonar_scanner |
| 主武器 | 0~600 | scrap_metal/energy_core | machine_gun(免费), howitzer(300+1), tank_gun(500+2), missile(600+1+1) |

### 阶段16-D Mark E.3 配件预升级实现细节

#### 费用公式（出击时结算）
| 等级 | 金币 | 素材 |
|------|------|------|
| Lv.1 | 基础 | 基础 |
| Lv.2 | 基础 + 50%基础 | 基础 + 1×基础 |
| Lv.3 | 基础 + 100%基础 | 基础 + 2×基础 |

#### 示例（Tier 3 配件：基础 400金, 1废金属）
| 等级 | 金币 | 废金属 |
|------|------|--------|
| Lv.1 | 400 | 1 |
| Lv.2 | 600 | 2 |
| Lv.3 | 800 | 3 |

#### 涉及文件
| 文件 | 变更 |
|------|------|
| `Scripts/EquipmentCostData.gd` | 新增 `MAX_ACCESSORY_LEVEL`、`get_accessory_total_cost()`，`calc_total_sortie_cost()` 读取配件等级 |
| `Scripts/Managers/gameManager.gd` | 新增 `set_accessory_level()`，修改 `get_brought_in_accessory_level()` 增加 clamp，`unload_part()` 重置等级 |
| `Scripts/UI/ListDisplay.gd` | 新增预升级等级控件（动态创建），等级调整后费用显示，描述按等级展示数值 |
| `Scripts/CarEditor.gd` | 连接 `accessory_level_changed` 信号刷新 UI |
| `scenes/autoload/debug_console.gd` | 新增 `acclv` 命令 |

### 关键架构决策
1. **MissionData 是纯数据**：不含逻辑参数（params/trigger），只存显示文本
2. **ObjectiveManager 管逻辑**：每个关卡场景树下放一个 ObjectiveManager 节点
3. **场景树优先**：尽量用 .tscn 子节点 + @onready，减少 new()+add_child()
4. **EnemyRank 枚举**：替代 is_elite/is_boss 布尔值 + scale 判定
5. **WeaponUpgradeHandler 中央管理**：所有武器升级效果通过 getter/callback 集中管理
6. **出击费用在出击时扣除**：装备时不扣费，出击确认时统一检查+扣除（策划书 5B.3）
7. **奖励由关卡脚本管理**：`_get_victory_bonus()` + `_get_objective_rewards()` 虚方法，不在 MissionData 硬编码
8. **预升级费用=出击费用的一部分**：等级越高出击越贵，而非一次性永久投资（策划书 5B.4）

### 重要文件路径
| 用途 | 路径 |
|------|------|
| 关卡配置表 | `Scripts/MissionData.gd` |
| 全局管理器 | `Scripts/Managers/gameManager.gd` |
| 装备费用表 | `Scripts/EquipmentCostData.gd` |
| 升级管理器 | `scenes/manager/upgrade_manager.gd` |
| 升级数据定义 | `Scripts/AbilityUpgradeData.gd` |
| 升级效果配置 | `Scripts/UpgradeEffectManager.gd` |
| 武器升级处理 | `Scripts/WeaponUpgradeHandler.gd` |
| 目标管理器 | `scenes/manager/objective_manager.gd` |
| 目标 HUD | `scenes/ui/objective_hud.gd` |
| 地图场景 | `scenes/ui/mission_map.gd` + `.tscn` |
| 军营场景 | `scenes/Levels/MilitaryCamp/MilitaryCamp.gd` |
| 关卡基类 | `scenes/Levels/base_level.gd` |
| 玩家脚本 | `scenes/game_object/player/player.gd` |
| 机炮弹体 | `scenes/ability/machine_gun_ability/machine_gun_ability.gd` |
| 主炮弹体 | `scenes/ability/tank_gun_ability/tank_shell.gd` |
| 榴弹弹体 | `scenes/ability/howitzer_ability/howitzer_shell.gd` |
| 导弹弹体 | `scenes/ability/missile_weapon_ability/missile_weapon_projectile.gd` |
| 机炮控制器 | `scenes/ability/machine_gun_ability_controller/machine_gun_ability_controller.gd` |
| 存档 | `Scripts/Save/SaveData.gd` |
| Debug 控制台 | `scenes/autoload/debug_console.gd` |
| 对话系统 | `scenes/autoload/dialogue_runner.gd` |
| 章节进度面板 | `scenes/ui/progression_hud.gd` |
| Boss 关卡 | `scenes/Levels/LevelBoss/level_boss.gd` + `LevelBoss.tscn` |
| Boss 敌人管理器 | `scenes/Levels/LevelBoss/boss_enemy_manager.gd` |
| 机械师对话 | `DialogueData/Dialogue2.dialogue` |
| 军需官对话 | `DialogueData/Dialogue3.dialogue` |

### 敌人场景路径
| class_name | 路径 |
|------------|------|
| SandScarab | `scenes/game_object/sand_scarab/` |
| SporeCaster | `scenes/game_object/spore_caster/` |
| DuneBeetle | `scenes/game_object/charger_enemy/` |
| BloatTick | `scenes/game_object/bomber_enemy/` |
| RustHulk | `scenes/game_object/tank_enemy/` |
| AcidSpitter | `scenes/game_object/spitter_enemy/` |
| BossTitan | `scenes/game_object/boss_titan/` |
| BossHive | `scenes/game_object/boss_hive/` |

### 关卡场景路由
| 关卡 ID | 场景 |
|---------|------|
| recon_patrol, salvage_run | LevelDesert |
| containment, extermination, outpost_defense, high_risk_sweep | LevelContaminated |
| titan_hunt, hive_assault | LevelBoss |
| (未匹配) | LevelTest (fallback) |

## 下一步

### 阶段 16：可选扩展（由用户决定优先级）
- ~~**Mark E.2**：装备/预制造 + 出击资源检查~~ → **✅ 已完成**（阶段16-B）
- ~~**Mark E.3**：配件预升级（策划书 5B.4）~~ → **✅ 已完成**（阶段16-D）
- **Mark X**：玩家升级与怪物经验掉落重做（待用户描述后实现）
- **62 个升级图标绘制**：详见 `DOCUMENTS/HANDOFFS/UPGRADE_ICON_DRAWING.md`
- ~~章节进度 UI~~ → **✅ 已完成**（阶段16-A：`ProgressionHUD`）
- ~~titan_hunt/hive_assault 独立关卡场景~~ → **✅ 已完成**（阶段16-B：LevelBoss）
- ~~目标奖励系统~~ → **✅ 已完成**（阶段16-C）
- ~~更多NPC对话内容~~ → **✅ 已完成**（阶段16-C：军需官 NPC）
- **新关卡/新敌人**：扩展 MissionData + 新关卡场景
- **数值平衡**：配装费用、敌人属性、Boss 血量等数值调优
- **费用平衡**：根据实际游戏测试调整各装备的出击费用

### 已知问题与注意事项
- 3 个升级 (`windmill_spread`、`windmill_speed`、`mine_multi_deploy`) 在 `UpgradeEffectManager` 中无配置，由各自控制器直接处理
- 32 个升级图标 PNG（Godot 报 "Not a PNG file"，外部查看器可正常显示），已移至 `.trash/Assets_Upgrades_png/`，`AbilityUpgradeData.upgrade_icons` 对应条目置为 null
- 如需恢复图标：将 `.trash/Assets_Upgrades_png/` 中文件复制回 `Assets/Upgrades/`，需修复 PNG 编码后恢复 preload
- 其余升级图标绘制任务详见 `DOCUMENTS/HANDOFFS/UPGRADE_ICON_DRAWING.md`
- ~~机炮弹体全局伤害加成不生效~~ → **已修复**（阶段16-A）
- ~~titan_hunt/hive_assault 无独立场景~~ → **已修复**（阶段16-B：LevelBoss）
- LevelBoss 场景的视觉/地形尚为简单占位（纯色背景 + 碰撞区域），后续可美化
- 军需官 NPC 使用与机械师相同的 NPC.png 精灵（色调不同），后续可替换为独立素材
- MilitaryCamp.tscn 中需要在 Godot 编辑器内为军需官节点设置 `qm_dialogue_resource` 导出变量指向 `DialogueData/Dialogue3.dialogue`

## 编码规范速查
1. **禁止 `:=`**：一律 `var x: Type = expr`
2. **禁止 preload 自身 .tscn**：用 `load()` 替代
3. **不考虑存档兼容**：改了就改了
4. **EnemyRank 枚举**：不用布尔值、不用 scale 判定
5. **敌人命名**：沙漠末世主题（污染生物/机械残骸）
6. **场景树优先**：尽量在 .tscn 中添加子节点，用 @onready 引用
7. **文件删除策略**：不确定的文件（特别是耗时生成的资源）移到 `.trash/` 假删除，仅确定无用的文件可直接删除
