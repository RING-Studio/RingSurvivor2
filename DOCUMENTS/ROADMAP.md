# ROADMAP

更新日期：2026-02-14

## 资料口径与过期说明
- 主口径：`DOCUMENTS/升级合集.md`、`DOCUMENTS/配件系统实现方案.md`、`DOCUMENTS/关卡.md`、`DOCUMENTS/策划书v2.md`
- 参考：`DOCUMENTS/新數據.md`（内容不全，仅作对照）
- 过期：`DOCUMENTS/数据整理.md`、`DOCUMENTS/幸存者武器装甲配件测试文档.md`（旧设定与旧表）
- 归档：`DOCUMENTS/策划书.md`（旧版口径，污染/时间相关以 `策划书v2.md` 为准）、`DOCUMENTS/旧设计档案.md`

## 当前实现基线（已具备）
- 玩家驾驶、碰撞受伤、经验升级、三选一升级流程
- 机炮主武器完整可用（扫射/风车/乱射/弹射/分裂/流血/溅射）
- 伤害公式（软攻/硬攻/穿深/覆甲率）与伤害数字颜色
- 升级池与品质、专属前置、前缀互斥
- 配件：地雷 + 专属强化（范围/装填速度/布雷/AT）；装填与冷却已统一为倍率设计（间隔=基础间隔/速度倍率，倍率≤0 为 INF）
- Level1 区域污染度与敌人生成框架

## 阶段 1：资料口径与数据收敛 ✅ 已完成
目标
- 明确文档与数据的唯一口径，消除历史冲突与旧表干扰
主要工作
- 统一升级 ID 与数值口径（如 `mine_range`、`mine_anti_tank`、`crit_rate` 品质）
- 对齐 `AbilityUpgradeData` / `UpgradeEffectManager` / `升级合集.md`
- 标记并隔离过期文档条目，避免被误用
验收标准
- 代码中所有升级条目在 `升级合集.md` 中可查且描述一致
- 关键冲突项完成统一并形成明确结论记录
- 升级池不再出现"文档不存在/代码无效果"的升级

**完成情况**：口径已统一（暴击/暴伤/冷却装置/地雷系）；射速·装填·冷却改为倍率设计并落地地雷；过期文档已标注；`cooling_device` 无冷却类配件时不入池。

## 阶段 2：核心战斗与关卡稳定 ✅ 已完成
目标
- Level1 可稳定运行 5-10 分钟，升级与战斗无明显逻辑错误
主要工作
- 校验 Region 逻辑与点污染度/上限/倍率公式的一致性
- 完成精英/BOSS 标记逻辑（支持地雷·AT）
- 补齐关键 TODO（如地雷爆炸表现、hit 信号用途）
验收标准
- Region1/2/3 的生成上限与倍率随污染度变化可复现
- BOSS 只生成一次且 `is_boss` 为真，精英 `is_elite` 可正确识别
- 机炮/地雷/升级流程无报错，伤害颜色与暴击逻辑正确

**完成情况**：Region 点污染度与属性倍率已与 `关卡.md` 对齐（REGION_1 倍率 1.0+污染度/1000，REGION_2/3 为 1.1+污染度/500）；BOSS 仅进入 Region3 时生成一次并设 `is_boss=true`；随机敌人生成 12% 概率精英（scale 2.0、`is_elite=true`），地雷·AT 可正确识别精英/BOSS；地雷爆炸增加扩散+淡出表现；`HurtboxComponent` 的 hit 信号仅对 weapon 伤害触发并已注释说明。

感想：
1、应当将hit信号扩展为weapon_hit等种类（hit也保留）。但是信号触发太频繁是不是会导致其他问题？
2、地雷的爆炸效果现在的实现不太好，我觉得得等我手动进行动画创建。不着急，因为不影响其他功能的实现。请你帮我mark一下，我准备好了自己进行

**Mark**：地雷爆炸表现已在 `mine_ability.gd` 的 `_play_explosion_effect()` 处标注为「待手动替换」占位，准备好后可用自制爆炸动画/粒子替换当前扩散+淡出实现。

## 阶段 3：通用升级与生存/机动扩展 ✅ 已完成
目标
- 将文档中的通用升级完整落地为可用效果
主要工作
- 实装 `repair_kit`、`cabin_ac`、`heat_sink` 等生存类升级
- 实装 `christie_suspension`、`gas_turbine`、`hydro_pneumatic` 等机动类升级
- 实装 `addon_armor`、`relief_valve` 等击穿减伤逻辑
验收标准
- 新增升级可抽取并可叠加生效
- 移速与回复等数值变化可在游戏中验证
- 击穿减伤仅在穿深大于装甲厚度时生效

**完成情况**：
- `repair_kit`：在 `player.gd` 中以定时器实现"每 N 秒回复 1 点耐久"，并按"冷却速度倍率"动态缩短间隔。
- `cabin_ac`：通过 `HealthComponent.healed` 信号触发 3 秒冷却加速（不可叠加），并在 buff 结束时自动恢复维护工具箱间隔。
- `heat_sink`：实现耐久上限惩罚（-5lv）与基于"差值×0.1lv%"的全局冷却速度加成（目前用于维护工具箱）。
- `christie_suspension` / `gas_turbine`：按等级提升 `VelocityComponent.max_speed`。
- `hydro_pneumatic`：已落地为"若存在移速惩罚（倍率<1），惩罚减半"的规则（当前版本无减速来源时无感知属正常）。
- `addon_armor` / `relief_valve`：在玩家受击（碰撞伤害）时，若满足"穿深 > 装甲厚度"则对最终伤害再乘以 \(1-\text{减免}\)。

## 阶段 4：配件系统扩展 ✅ 已完成
目标
- 从"地雷单配件"扩展为多配件组合玩法
主要工作
- 落地至少 3 个主动配件（烟雾弹/无线电/激光压制/外挂导弹任选）
- 落地 1-2 个被动配件（纤维内衬/爆反/红外对抗）
- 接入 `cooling_device` 的全局配件冷却效果
- 配件专属强化进入升级池并影响对应配件
验收标准
- 配件可在局内获得并触发效果，伤害来源显示为 `accessory`
- 专属强化仅在拥有对应配件时出现
- `cooling_device` 对所有配件冷却生效且可叠加

**完成情况**：
- 主动配件已落地：`smoke_grenade`（装填类）、`radio_support` / `laser_suppress` / `external_missile`（冷却类）。
- 视觉占位：烟雾弹云团用 alpha=64 的圆形绘制占位（`smoke_cloud.gd` 的 `_draw()`），后续可替换为粒子/动画。
- `cooling_device`：对冷却类配件的冷却计时生效（radio/laser/missile），可叠加。
- 专属强化：烟雾弹（范围/持续）、无线电（半径）、外挂导弹（伤害）均为 `exclusive_for`，仅在拥有对应配件后进入池。
- `radio_support`：按文档"不分敌我"，炮击范围内玩家也会受伤（当前实现为直接扣耐久）。
- `laser_suppress`：目标锁定依赖敌人 `is_aiming_player` 状态；当前以"WizardEnemy 5米内视为瞄准"做简化实现（后续接入真实瞄准/射击状态可替换）。
- `ir_counter`：恢复原设计——5米内"正在瞄准玩家"的最近远程敌人穿甲率固定为0%（当前实现为该敌人的 `hard_attack_depth_mm` 视为 0，从而不触发击穿）。
- 被动配件：`spall_liner` / `era_block` 已实现"一次性免死"，并下沉到 `HealthComponent.damage()` 前一层拦截（覆盖所有调用 `HealthComponent.damage()` 的伤害入口；若未来引入新的受伤入口仍应走 HealthComponent）。

## 阶段 5：主武器扩展与差异化 ✅ 已完成
目标
- 完成多主武器形态并形成玩法差异
主要工作
- 实装 `howitzer` / `tank_gun` / `missile` 中至少两种（本阶段：三种均已落地）
- 补齐武器专属升级与 `exclusive_for` 规则
验收标准
- 切换主武器后控制器与升级池正确切换
- 不同主武器具备明显差异化射击方式

**完成情况**：
- 主武器控制器已新增：`HowitzerAbilityController`、`TankGunAbilityController`、`MissileWeaponAbilityController`，并在 `player.gd` 按 `主武器类型` 动态实例化。
- 差异化：
  - `howitzer`：慢射 + 爆炸 AOE（范围伤害占位使用红色 alpha=64 圆形）。
  - `tank_gun`：单发高速炮弹 + 可穿透（受 `penetration` 与专属穿透强化影响），并支持专属"穿深"加成。
  - `missile`：锁定最近敌人追踪飞行，命中/超时爆炸 AOE（占位使用红色 alpha=64 圆形）。
- 升级池切换：
  - `UpgradeManager._add_exclusive_upgrades_for_weapon()` 已扩展支持 `howitzer` / `tank_gun` / `missile`，进入关卡时按当前主武器把对应 `exclusive_for` 的专属强化加入池。
- 专属强化新增（示例）：
  - `howitzer_reload` / `howitzer_radius`
  - `tank_gun_depth` / `tank_gun_penetration`
  - `missile_salvo` / `missile_reload`

## 阶段 6：元进度、基地与叙事
目标
- 实现"局外基地—局内战斗—结算回基地"的循环
主要工作
- 污染值/天数/时间段推进与存档
- 基地交互（任务选择、载具编辑、AVG 对话）
- （延期）"设为出战/当前出战"按钮与多车型出战选择，待 MAP/任务选择界面阶段一并实现
验收标准
- 完整流程可跑通：开始界面 → 基地 → 关卡 → 结算 → 基地
- 存档可恢复污染值、天数、车辆配置与解锁内容

**当前进度（2026-02-11）**：
- 已完成：结算回基地链路打通；任务胜负均推进时间段并自动存档；污染变动默认规则已落地（胜利 `floor(污染*0.9)+300`，失败 `+300`，下限 `0`）。
- 待完成：任务选择/MAP 界面、任务条件校验细化、基地内"任务信息与结果反馈"UI。

## 阶段 7：升级池大扩充（设计落表）✅ 已完成
目标
- 完成"基础升级 100 项（不含后置）+ 配件 35 项"的统一设计口径
主要工作
- 新增扩充文档：`DOCUMENTS/升级扩充清单v1.md`
- 按"通用强化 / 主武器通用强化 / 配件"三大类完成 100 项落表
- 补齐前置/后置关系模板与协同组合建议（后置不计入 100）
验收标准
- 基础条目总数达到 100，且配件不少于 35
- 所有条目具备唯一 ID、类型、品质与 MaxLevel 约束
- 前置后置关系可直接映射到 `exclusive_for` 机制

**完成情况**：已完成落表与统计；实现阶段尚未开始。

## 阶段 8：扩充第一批实现（12 配件 + 20 强化）✅ 已完成
目标
- 在不破坏当前可玩闭环的前提下，先落地一批"高体感"新增内容
主要工作
- 配件优先：`decoy_drone`、`auto_turret`、`repair_beacon`、`shield_emitter`、`emp_pulse`、`grav_trap`、`thunder_coil`、`cryo_canister`、`incendiary_canister`、`acid_sprayer`、`orbital_ping`、`med_spray`
- 强化优先：`armor_breaker`、`weakpoint_strike`、`overdrive_trigger`、`recoil_compensator`、`execution_protocol` 等 20 项
- 完成对应数据接入：`AbilityUpgradeData` + `UpgradeEffectManager` + `UpgradeManager` 入池规则
验收标准
- 新增 12 个配件均可在局内触发且无报错
- 新增 20 个强化可抽取、可升级、可叠加
- 单局中至少能稳定出现 2 种新增配件构筑路线

**完成情况（2026-02-13）**：
- 8.1~8.5 全部完成。12 个配件控制器 + 20 个强化数据/效果全部落地。
- player.gd 配件实例化已重构为 `ACCESSORY_CONTROLLER_MAP` 统一管理 17 种配件。
- shield_emitter 护盾吸收已接入 `before_take_damage` 管线。
- CarEditor 配件面板已修复：选项保持、图标显示、描述参数替换 + BBCode。
- 遗留打磨项已移至 Mark A（弹道接口实际生效、视觉占位替换等）。

## 阶段 9：扩充第二批实现（余下配件 + 后置链第一批）✅ 已完成
目标
- 将配件总量扩到 35，并让构筑深度来自"前置→后置"链路
主要工作
- 补齐未实现的新增配件至 35
- 上线后置链第一批（每个已实现配件至少 2 条后置）
- 完善互斥、权重、品质分布，避免升级池被稀释
验收标准
- 配件总量达到 35，后置链可通过 `exclusive_for` 正常触发
- 抽卡体验中"白板项过多"问题可控（有可量化权重方案）
- 现有老构筑（机炮/地雷/导弹）不被新系统破坏

**完成情况（2026-02-13）**：
- 已新增 13 个配件 + 旧配件后置链第一批（36 条）全部落地
- 品质分布微调（白/蓝/紫/红 80/15/4/1，不改变同品质等概率）
- 待完成：进一步平衡数值与视觉占位替换（权重/同品质等概率未改动）

## 阶段 10：怪物扩展与 LevelTest ✅ 已完成
目标
- 丰富敌人种类（新小怪/精英增强/Boss），在 LevelTest 中可测试验证
主要工作
- 10.1 将现有 Level1 重命名为 LevelTest（场景 + 脚本 + 引用）
- 10.2 实现新敌人（6种，弃用外部模板，全部重做沙漠/污染主题）
- 10.3 EnemyRank 枚举重构（替代 is_elite/is_boss + scale 判定）
- 10.4 实现 Boss：BossTitan（污染巨兽）、BossHive（孵化母体）
- 10.5 将新敌人接入 LevelTest 生成表进行测试
验收标准
- 6 种小怪可正常生成、行为正确、可被击杀
- EnemyRank 枚举判定精英/Boss 生效
- 2 种 Boss 可通过区域触发生成
- LevelTest 可稳定运行 5 分钟以上

**当前进度（2026-02-14）**：
- 10.1 ✅ Level1 已重命名为 LevelTest（场景/脚本/引用全部更新）
- 10.2 ✅ 6 种敌人已实现（弃用外部模板 basic_enemy/wizard_enemy，全部重做）：
  - SandScarab（沙漠圣甲虫）—— 基础近战，追踪玩家
  - SporeCaster（孢子投手）—— 中距离远程，停下射击孢子弹，具有 is_aiming_player
  - DuneBeetle（沙丘甲虫）—— 冲锋型：追踪→蓄力→冲刺→眩晕
  - BloatTick（膨爆蜱）—— 自爆型：接近玩家自爆 AoE，被击杀也爆炸
  - RustHulk（锈壳重甲）—— 重装机械：高装甲+高HP+免疫击退
  - AcidSpitter（酸液射手）—— 远程：保持距离发射酸液弹丸
- 10.3 ✅ EnemyRank 枚举替代 is_elite/is_boss 布尔值，删除所有 scale 判定逻辑
  - `enum EnemyRank { NORMAL=0, ELITE=1, BOSS=2 }`
  - 精英增幅：scale 1.5、HP×3、药瓶必掉
  - mine_ability 等判定已切换为 `enemy_rank >= 1`
- 10.5 ✅ 新敌人已接入 LevelTest 生成表（权重：圣甲虫4/孢子投手2/沙丘甲虫2/膨爆蜱1/锈壳重甲1/酸液射手1）
- 10.4 ✅ Boss 已实现：BossTitan（污染巨兽，冲击波AoE）、BossHive（孵化母体，召唤小怪）
  - LevelTest Region3 默认生成 BossTitan，可通过 `spawn_boss("boss_hive")` 切换
- ⏳ MissionData 已更新为 8 关卡配置（含目标类型、解锁链、难度星级）
- ⏳ MissionSelectPanel 已增强（难度星级显示、目标描述、解锁链检查）
- ⏳ 军营 MissionMap 已实现玩家控制禁用/恢复
- 注意事项更新：禁止使用 `:=` 进行类型推断，一律显式声明类型
- 修复：machine_gun_ability.gd 自身 preload 自身 .tscn 导致 "Parse Error: Busy" 循环加载，改用 load()

## 阶段 11：关卡系统与 MissionMap ✅ 已完成
目标
- 实现完整的关卡选择 → 关卡内战斗 → 结算闭环
主要工作
- 11.1 MissionData 重构为纯数据表（objectives 仅存显示信息，无逻辑参数）
- 11.2 MissionMap 地图场景（目的地图标 + 点击弹出任务面板）
- 11.3 ObjectiveManager（关卡内目标逻辑管理）+ ObjectiveHUD（目标 HUD 显示）
- 11.4 关卡结算 + Roguelike 升级清空
- 11.5 关卡解锁链 + 场景路由 + Boss 条件生成

**已完成内容**：
- ✅ MissionData 简化：objectives 只含 id/display_name/primary，无 params/trigger/逻辑
- ✅ DESTINATIONS 目的地系统（6 个目的地 + 关联关卡）
- ✅ MissionMap 地图场景：目的地按钮 + 右侧详情面板 + 目标列表显示
- ✅ MilitaryCamp 使用 MissionMap（替代旧 MissionSelectPanel）
- ✅ ObjectiveManager：Node 子节点，负责目标状态/进度/触发链/胜负判定
- ✅ ObjectiveHUD：PanelContainer 子节点（在 CanvasLayer 下），从 ObjectiveManager 读取状态
- ✅ ObjectiveManager + ObjectiveHUD 作为 LevelTest.tscn 场景树子节点（非 new/add_child）
- ✅ 关卡结算：apply_mission_result 记录通关 + 已完成目标
- ✅ Roguelike 升级清空：start_mission() 清空 current_upgrades + roll_points
- ✅ Boss 条件生成：reach_area → 触发链解锁 boss_kill → Region3 生成 Boss
- ✅ 策划书v2 全面更新

---

## 阶段 12：关卡进阶与实体系统 ✅ 已完成
目标
- 实现收集物/据点等关卡实体，丰富目标类型的可玩性
主要工作
- 12.1 收集物系统（掉落物拾取 → ObjectiveManager.report_progress）
- 12.2 防守据点实体（有 HP、可被敌人攻击、毁坏触发 report_fail）
- 12.3 次要目标奖励实际发放逻辑（money/材料入账）
- 12.4 关卡难度递增（根据 mission.difficulty 调整敌人属性/密度/精英率）
验收标准
- collect 和 defend 目标类型可正常运作
- 次要目标完成后奖励正确入账

**完成情况（2026-02-14）**：
- 12.1 ✅ `Collectible` 实体（`scenes/game_object/collectible/`）：磁吸拾取、浮动动画、全局信号 `collectible_collected`
  - `CollectibleDropComponent`（`scenes/component/`）：可挂在敌人身上，按概率/类型过滤掉落
  - LevelTest 集成：`salvage_run` 掉落能量核心(30%)，`hive_assault` 膨爆蜱掉落生物样本(40%)
- 12.2 ✅ `DefendOutpost` 实体（`scenes/game_object/defend_outpost/`）：有 HP、血条、敌人接近造成伤害、毁坏信号
  - LevelTest 集成：`outpost_defense` 在地图中心生成据点，毁坏 → `report_fail("defend_outpost")`
  - 次要目标：据点血量 <50% → `report_fail("defend_no_hit")`
- 12.3 ✅→⚠️ 目标奖励框架（已修正）：
  - 原实现（刚性 `OBJECTIVE_REWARDS` + `MISSION_VICTORY_REWARDS` 表）已移除
  - 奖励不局限于 money，可含素材、解锁、主线推进等多种组合
  - 奖励由关卡脚本全权管理，不在 MissionData 硬编码
  - `_build_settlement()` 保留结算信息钩子，待 Mark C 实现完整发放
  - MissionMap 不显示奖励，但已显示"已完成目标"绿色 ✓
- 12.4 ✅ 关卡难度递增：`mission.difficulty` 1~5 影响：
  - HP 倍率：1.0/1.2/1.5/1.8/2.2
  - 生成上限：+0/+2/+4/+6/+8
  - 精英概率：12%/15%/20%/25%/30%
  - 高难度缩短生成间隔

## 阶段 13：独立关卡场景
目标
- 为不同关卡创建独立场景，摆脱全部使用 LevelTest 的现状
主要工作
- 13.1 创建 2~3 个独立关卡场景（不同地形/区域/敌人组合）
- 13.2 每个场景配置自己的 ObjectiveManager 目标（不再依赖 match mission_id）
- 13.3 场景内特殊机制（不同地形效果、环境危害等）
验收标准
- 至少 3 个独立关卡可进入并完成

## 阶段 14：NPC 对话与剧情推进
目标
- 实现 NPC 对话系统和主线/支线目标
主要工作
- 14.1 NPC 对话文本与进度追踪（npc_dialogues）
- 14.2 主线/支线目标系统 UI 展示与奖励发放
- 14.3 剧情推进触发（章节完成条件）

---

## 长期 Mark（非当前阶段）

### Mark A：单局体验打磨（后置）
- 目标：把"扩充数量"转化为"可读、可选、可玩"的稳定体感
- 内容：构筑平衡、节奏校准、反馈特效、文案与提示优化
- 来自阶段8遗留：✅ 弹道接口生效；✅ 机炮目标特定加成；⏳ 视觉占位替换；⏳ 地雷爆炸特效

### Mark V：美术与视觉
- MissionMap 地图美化（背景图、目的地图标素材）
- 概念图 pptx 对应 UI 还原
- 敌人/配件视觉占位替换
- 各种特效完善

### Mark S：纯代码实体 → tscn 场景化（后置）
- 目标：将当前通过 `.new()` 纯代码实例化的实体改为 `.tscn` 场景文件，方便手动编辑视觉/碰撞等
- 优先级：低（当前功能正常，但不利于美术替换和编辑器调试）
- 涉及实体（共 10 个）：

| # | 当前脚本路径 | 实例化方式 | 说明 |
|---|-------------|-----------|------|
| 1 | `scenes/ability/auto_turret_ability/auto_turret.gd` | `AutoTurret.new()` | 自动炮塔实体 |
| 2 | `scenes/ability/decoy_drone_ability/decoy_drone.gd` | `DecoyDrone.new()` | 诱饵无人机实体 |
| 3 | `scenes/ability/repair_beacon_ability/repair_beacon.gd` | `RepairBeacon.new()` | 修复信标实体 |
| 4 | `scenes/ability/grav_trap_ability/grav_trap.gd` | `Node2D.new() + set_script` | 引力陷阱区域 |
| 5 | `scenes/ability/incendiary_canister_ability/fire_zone.gd` | `Node2D.new() + set_script` | 燃烧区域 |
| 6 | `scenes/ability/cryo_canister_ability/cryo_zone.gd` | `Node2D.new() + set_script` | 冰冻区域 |
| 7 | `scenes/ability/radio_support_ability/radio_blink_circle.gd` | `Node2D.new() + set_script` | 炮击闪烁圈 |
| 8 | `scenes/game_object/bomber_enemy/bomber_explosion_effect.gd` | `Node2D.new() + set_script` | 膨爆蜱爆炸特效 |
| 9 | `scenes/game_object/spitter_enemy/spitter_projectile.gd` | `Node2D.new() + set_script` | 酸液射手弹丸 |
| 10 | `scenes/game_object/spore_caster/spore_projectile.gd` | `Node2D.new() + set_script` | 孢子投手弹丸 |

- 改造步骤模板：创建 `.tscn` → 移入子节点（碰撞体/粒子/精灵）→ Controller 改用 `load().instantiate()` → 测试

### Test Mark（待测试）
- 主武器弹道配件效果
- 机炮目标特定加成
- 阶段9~10 配件与怪物行为
- Roguelike 升级清空流程
- 阶段12 收集物拾取、据点防守、奖励结算、难度缩放

### Mark T：科技处废除 ✅ 已完成
- 原有的"科技处"场景（TechScene）和相关逻辑已废除
- 已删除：`Scripts/TechScene.gd`、`Scripts/TechList.gd`、`scenes/Levels/TechScene.tscn`
- 已清理：军营 TechBase 建筑节点、`tech_scene` 导出变量、`tech_upgrades` 存档字段
- `GameManager.tech_upgrades` 已替换为 `GameManager.materials`（素材库）

### Mark B：资源回流与局外成长（后置）
- 目标：让"打完一局回基地"有长期收益和策略价值
- 内容：结算资源统一入账、成长曲线、失败补偿、存档扩展
- 触发时机：任务系统最小闭环跑通后

### Mark E：配装系统进阶
- 目标：实现完整的"解锁 → 装备（预制造）→ 出击结算"配装闭环
- 前置：Mark C（带出物品系统提供素材来源）
- 详见策划书 5B

#### E.1 解锁系统
- 配件解锁条件：默认为"在某局任务中选择过一次该升级"
- 武器/装甲解锁条件：怪物素材 + 任务推进（各不相同，具体待定）
- 未达成条件：显示"未解锁"+ 条件描述
- 达成条件：显示解锁按钮

#### E.2 装备 / 预制造
- 解锁后的配件/武器/装甲可"装备"
- 装备需花费资源（能量/money、怪物素材等）
- 资源在**出击时结算**而非装备时扣除
- 出击时资源不足 → 提示并禁止出击

#### E.3 配件升级 / 预升级（E.2 完成后设计）
- 装备某配件后可选择对其升级
- 升级同样为预升级，出击时结算

#### 实现顺序
1. E.1 解锁系统（含 UI 改造）
2. E.2 装备 / 预制造 + 出击资源检查
3. E.3 配件预升级

### Mark C：任务结算与带出物品系统
- 目标：实现完整的"关卡结算 → 带出物品 → 局外资源积累"闭环
- 触发时机：阶段 13~14 完成后，或 Mark B 启动时一并实现

#### 背景设定（污染能量）
玩家阵营配备污染转换器，可将污染怪物身上提取的"污染能量"转换为可用能量。
集齐一定能量即可进行一次"升级"。但升级在污染转换器过载后（即任务时限结束）会失效，
返还一定数量能量并存入能量池（即局外能量）。

#### 关卡结束结算规则
在任务完成（无论胜负）后，进行"带出物品"结算：

**1. 胜利情况**
- 带出全部物品（怪物素材 + 升级返还能量）

**2. 失败 + 玩家死亡**
- 依照关卡规则损失随机比例的**大部分**物品（例如 60%~90% 损失）

**3. 失败 + 玩家存活**
- 依照关卡规则损失随机比例的**小部分**物品（例如 10%~30% 损失）

**4. 规则由关卡脚本全权管理**
- 不同关卡可自定义损失比例、免损物品等
- 以上仅为默认参考规则

#### 带出物品内容
**a. 怪物素材**
- 击杀敌人掉落的素材类收集物（bio_sample、energy_core 等）
- 由关卡内实际收集到的数量决定

**b. 升级返还能量**
- 所有局内获得的升级（包括带入配件）按"价值"以随机比例返还为污染能量
- 价值由**品质 × 等级 × 等级上限**唯一确定（具体公式待定，如 `价值 = 品质基准 × 等级 / 等级上限 × 10`）
- 返还比例受关卡结果影响（胜利 100%、失败存活 70~90%、失败死亡 10~40%）

#### 待定事项
- [ ] 升级价值公式确定（品质基准值：白=1, 蓝=3, 紫=8, 红=20？）
- [ ] end_mission 时机：当前在 start_mission 清空升级，考虑在 end_mission 计算返还后再清空
- [x] 素材存档字段（`GameManager.materials` + `SaveData` 已加入）
- [ ] 结算 UI：end_screen 扩展显示带出物品列表
- [ ] 目标奖励由关卡脚本管理（可触发 money/素材/解锁/主线推进等多种组合）
