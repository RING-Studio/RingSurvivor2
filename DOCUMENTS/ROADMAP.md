# ROADMAP

更新日期：2026-02-12（二次更新）

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
- 升级池不再出现“文档不存在/代码无效果”的升级

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
- `repair_kit`：在 `player.gd` 中以定时器实现“每 N 秒回复 1 点耐久”，并按“冷却速度倍率”动态缩短间隔。
- `cabin_ac`：通过 `HealthComponent.healed` 信号触发 3 秒冷却加速（不可叠加），并在 buff 结束时自动恢复维护工具箱间隔。
- `heat_sink`：实现耐久上限惩罚（-5lv）与基于“差值×0.1lv%”的全局冷却速度加成（目前用于维护工具箱）。
- `christie_suspension` / `gas_turbine`：按等级提升 `VelocityComponent.max_speed`。
- `hydro_pneumatic`：已落地为“若存在移速惩罚（倍率<1），惩罚减半”的规则（当前版本无减速来源时无感知属正常）。
- `addon_armor` / `relief_valve`：在玩家受击（碰撞伤害）时，若满足“穿深 > 装甲厚度”则对最终伤害再乘以 \(1-\text{减免}\)。

## 阶段 4：配件系统扩展 ✅ 已完成
目标
- 从“地雷单配件”扩展为多配件组合玩法
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
- `radio_support`：按文档“不分敌我”，炮击范围内玩家也会受伤（当前实现为直接扣耐久）。
- `laser_suppress`：目标锁定依赖敌人 `is_aiming_player` 状态；当前以“WizardEnemy 5米内视为瞄准”做简化实现（后续接入真实瞄准/射击状态可替换）。
- `ir_counter`：恢复原设计——5米内“正在瞄准玩家”的最近远程敌人穿甲率固定为0%（当前实现为该敌人的 `hard_attack_depth_mm` 视为 0，从而不触发击穿）。
- 被动配件：`spall_liner` / `era_block` 已实现“一次性免死”，并下沉到 `HealthComponent.damage()` 前一层拦截（覆盖所有调用 `HealthComponent.damage()` 的伤害入口；若未来引入新的受伤入口仍应走 HealthComponent）。

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
  - `tank_gun`：单发高速炮弹 + 可穿透（受 `penetration` 与专属穿透强化影响），并支持专属“穿深”加成。
  - `missile`：锁定最近敌人追踪飞行，命中/超时爆炸 AOE（占位使用红色 alpha=64 圆形）。
- 升级池切换：
  - `UpgradeManager._add_exclusive_upgrades_for_weapon()` 已扩展支持 `howitzer` / `tank_gun` / `missile`，进入关卡时按当前主武器把对应 `exclusive_for` 的专属强化加入池。
- 专属强化新增（示例）：
  - `howitzer_reload` / `howitzer_radius`
  - `tank_gun_depth` / `tank_gun_penetration`
  - `missile_salvo` / `missile_reload`

## 阶段 6：元进度、基地与叙事
目标
- 实现“局外基地—局内战斗—结算回基地”的循环
主要工作
- 污染值/天数/时间段推进与存档
- 基地交互（任务选择、载具编辑、AVG 对话）
- （延期）“设为出战/当前出战”按钮与多车型出战选择，待 MAP/任务选择界面阶段一并实现
验收标准
- 完整流程可跑通：开始界面 → 基地 → 关卡 → 结算 → 基地
- 存档可恢复污染值、天数、车辆配置与解锁内容

**当前进度（2026-02-11）**：
- 已完成：结算回基地链路打通；任务胜负均推进时间段并自动存档；污染变动默认规则已落地（胜利 `floor(污染*0.9)+300`，失败 `+300`，下限 `0`）。
- 待完成：任务选择/MAP 界面、任务条件校验细化、基地内“任务信息与结果反馈”UI。

## 阶段 7：升级池大扩充（设计落表）✅ 已完成
目标
- 完成“基础升级 100 项（不含后置）+ 配件 35 项”的统一设计口径
主要工作
- 新增扩充文档：`DOCUMENTS/升级扩充清单v1.md`
- 按“通用强化 / 主武器通用强化 / 配件”三大类完成 100 项落表
- 补齐前置/后置关系模板与协同组合建议（后置不计入 100）
验收标准
- 基础条目总数达到 100，且配件不少于 35
- 所有条目具备唯一 ID、类型、品质与 MaxLevel 约束
- 前置后置关系可直接映射到 `exclusive_for` 机制

**完成情况**：已完成落表与统计；实现阶段尚未开始。

## 阶段 8：扩充第一批实现（12 配件 + 20 强化）⏳ 进行中
目标
- 在不破坏当前可玩闭环的前提下，先落地一批“高体感”新增内容
主要工作
- 配件优先：`decoy_drone`、`auto_turret`、`repair_beacon`、`shield_emitter`、`emp_pulse`、`grav_trap`、`thunder_coil`、`cryo_canister`、`incendiary_canister`、`acid_sprayer`、`orbital_ping`、`med_spray`
- 强化优先：`armor_breaker`、`weakpoint_strike`、`overdrive_trigger`、`recoil_compensator`、`execution_protocol` 等 20 项
- 完成对应数据接入：`AbilityUpgradeData` + `UpgradeEffectManager` + `UpgradeManager` 入池规则
验收标准
- 新增 12 个配件均可在局内触发且无报错
- 新增 20 个强化可抽取、可升级、可叠加
- 单局中至少能稳定出现 2 种新增配件构筑路线

**当前进度（2026-02-12 二次更新）**：
- ✅ 8.1 升级重命名：28 条现有升级 name 字段已按新升级选项更新
- ✅ 8.2 新增 20 个强化数据条目（AbilityUpgradeData + UpgradeEffectManager）
- ✅ 8.3 新增 12 个配件数据条目（同上）
- ✅ 8.4 新增强化效果逻辑接入：
  - player.gd：应急抢修、加固隔舱、动能缓冲、超压限制器、机动伺服、火控计算机
  - WeaponUpgradeHandler.gd：战场感知、过载触发器、终结协议、击杀链、穿甲弹芯、弱点打击、电击核心、破片DoT链
  - 新增弹道接口（弹速/寿命/散布角/后坐力上限）已暴露给武器控制器
  - AOE 武器重构为逐目标伤害修正；所有武器已接入通用击杀通知
- ✅ 8.5 新增 12 个配件场景和控制器：
  - 12 个控制器全部创建完毕：`decoy_drone`、`auto_turret`、`repair_beacon`、`shield_emitter`、`emp_pulse`、`grav_trap`、`thunder_coil`、`cryo_canister`、`incendiary_canister`、`acid_sprayer`、`orbital_ping`、`med_spray`
  - player.gd 已重构配件实例化逻辑：抽出 `ACCESSORY_CONTROLLER_MAP` + `_has_accessory_controller()` + `_instantiate_accessory_controller()` 统一管理 17 种配件
  - shield_emitter 护盾吸收已接入 `before_take_damage` 管线（护盾 → 减伤 → 免死）
  - 各控制器均支持 `cooling_device` 冷却加速、`damage_bonus`/`crit_rate`/`crit_damage` 加成
- ⏳ 8.6 接入验证与打磨：
  - 弹道接口需各武器控制器调用才实际生效；机炮子弹目标特定加成待后续补充
  - 部分控制器使用视觉占位（AoECircleEffect），后续需替换为正式特效
  - `breach_equip`（破障设备）的 controller 在旧代码中为碰撞逻辑内处理，暂不需要独立控制器

## 阶段 9：扩充第二批实现（余下配件 + 后置链第一批）
目标
- 将配件总量扩到 35，并让构筑深度来自“前置→后置”链路
主要工作
- 补齐未实现的新增配件至 35
- 上线后置链第一批（每个已实现配件至少 2 条后置）
- 完善互斥、权重、品质分布，避免升级池被稀释
验收标准
- 配件总量达到 35，后置链可通过 `exclusive_for` 正常触发
- 抽卡体验中“白板项过多”问题可控（有可量化权重方案）
- 现有老构筑（机炮/地雷/导弹）不被新系统破坏

## 阶段 10：任务系统最小闭环（无 MAP 先行）
目标
- 在不实现完整 MAP 的前提下，形成“任务选择→任务结算差异”的可配置系统
主要工作
- 增加任务配置数据（任务ID、时段消耗、胜败污染公式、奖励预览）
- 基地“出击点”接入任务选择弹窗（最小UI：列表+详情+确认）
- 支持特殊任务消耗 2 时间段；夜晚可否出击由任务配置决定
验收标准
- 至少 3 个任务可选且污染变动结果可区分
- 同一天内因时段不足无法接取高消耗任务时有明确提示
- 任务配置改动可直接影响结算，无需改脚本逻辑

## 长期 Mark（非当前阶段）

### Mark A：单局体验打磨（后置）
- 目标：把“扩充数量”转化为“可读、可选、可玩”的稳定体感
- 内容：构筑平衡、节奏校准、反馈特效、文案与提示优化
- 触发时机：阶段 8/9 完成且核心扩充功能稳定后

### Mark B：资源回流与局外成长（后置）
- 目标：让“打完一局回基地”有长期收益和策略价值
- 内容：结算资源统一入账、成长曲线、失败补偿、存档扩展
- 触发时机：任务系统最小闭环跑通后
