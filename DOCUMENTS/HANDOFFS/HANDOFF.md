# 交接文档 — 供下次对话使用

更新日期：2026-02-19（阶段15 升级扩充第三批 + Mark D 代码清理）

## 如何使用本文档
在新的对话开始时，请 AI 阅读以下文件以快速恢复上下文：
1. **本文档**：`DOCUMENTS/HANDOFF.md`（当前进度摘要）
2. **策划书**：`DOCUMENTS/策划书v2.md`（游戏设计全貌）
3. **ROADMAP**：`DOCUMENTS/ROADMAP.md`（开发进度与规划）
4. **注意事项**：`DOCUMENTS/注意事项.md`（编码规范）
5. **关卡设计**：`DOCUMENTS/关卡.md`（敌人/关卡/目标系统详细设计）
6. **Cursor 规则**：`.cursor/rules/gdscript-coding-standards.mdc`（自动应用的编码规范）

## 项目概述
- **引擎**：Godot 4.5.1 (GDScript)
- **类型**：类幸存者 Roguelike + AVG + 基地经营
- **背景**：沙漠末世，军营绿洲小城，驾驶改装车辆在污染区执行任务

## 当前完成状态（截至 Mark D 代码清理 + 2026-02-19 审查）

### 核心系统已实现
- **升级系统**：Roguelike 单局升级池（白/蓝/紫/红品质）、配件+强化、互斥升级
- **武器系统**：机炮（主武器）+ 多种配件能力（地雷、榴弹、导弹等 30+种）
- **战斗系统**：装甲/覆甲/穿透管线、暴击、击退、减速、冲击波等
- **敌人系统**：6 种小怪 + 2 种 Boss（沙漠/污染主题），EnemyRank 枚举
- **关卡系统**：
  - `MissionData.gd`：纯数据表（8 个关卡 + 6 个目的地），objectives 仅含显示信息
  - `ObjectiveManager`：关卡场景树子节点，管理目标逻辑/进度/触发链
  - `ObjectiveHUD`：关卡场景树子节点，显示目标 HUD
  - `MissionMap`：军营覆盖层地图场景（替代旧 MissionSelectPanel）
- **收集物系统**（阶段12新增）：
  - `Collectible` 实体：磁吸拾取、全局信号、可配置类型/颜色
  - `CollectibleDropComponent`：挂在敌人上，按概率/类型过滤掉落
  - 已接入：salvage_run（能量核心）、hive_assault（生物样本）
- **防守据点**（阶段12新增）：
  - `DefendOutpost` 实体：有 HP、血条、敌人接近造成伤害、毁坏信号
  - 已接入 outpost_defense 关卡（据点毁坏 → report_fail）
- **结算框架**（阶段12新增，已修正）：
  - 奖励不限于 money，可含素材/解锁/主线推进等组合，由关卡脚本管理
  - `_build_settlement()` 记录结算信息钩子，待 Mark C 实现完整发放
- **难度缩放**（阶段12新增）：
  - `mission.difficulty` 1~5 影响 HP 倍率、生成上限、精英概率、生成间隔
- **车辆配装**：CarEditor 场景，主武器+带入配件选择（进阶配装系统见 Mark E）
- **存档系统**：SaveData（不考虑存档兼容），已含 `materials` 素材库字段
- **Roguelike 清空**：每局开始清空 current_upgrades + roll_points
- **科技处已废除**：TechScene/TechList 已删除，军营 TechBase 建筑已移除
- **DebugConsole 全局控制台**（autoload）：
  - 任意场景键入 DEBUG 激活调试模式，按 \` 呼出控制台
  - 命令：unlock / add / get / god / win / lose / xp / kill / list / time / save / npc / info / unlock_acc
  - God Mode 使玩家免伤，debug_mode 使升级 roll 无限，= 键快速加经验
  - `npc` 查看/设置 NPC 对话进度、`info` 游戏状态总览、`unlock_acc` 解锁配件
  - 控制台打开时自动阻止玩家移动（`is_consuming_input` 标志）
  - 使用文档：`DOCUMENTS/DEBUG_CONSOLE.md`
- **DialogueRunner 对话系统**（autoload，阶段14.1）：
  - `scenes/autoload/dialogue_runner.gd` — 统一 AVG 对话入口
  - overlay 模式：气泡覆盖在当前场景上方，不遮挡画面
  - fullscreen 模式：全屏遮罩 + 可选背景图 / 角色立绘 + 气泡
  - 配置项：`pause_scene`（默认暂停）、`free_scene` + `next_scene`（场景切换）
  - 军营 NPC 已使用 fullscreen 模式（不离开军营场景）
  - 基于 `dialogue_manager` 插件的 `DialogueManager.show_dialogue_balloon()`
- **BaseLevel 基类**（阶段13新增）：
  - `scenes/Levels/base_level.gd` 提供通用关卡逻辑
  - 子类通过虚方法覆写定义关卡特有行为
  - LevelTest/LevelDesert/LevelContaminated 均继承 BaseLevel
- **结算与带出物品系统**（Mark C 完成）：
  - 升级返还能量：`品质基准 × 等级 / max(等级上限, 等级) × 10`
  - 品质基准值：白=1, 蓝=3, 紫=8, 红=20
  - 素材带出：收集物拾取自动记录到 `session_materials`
  - 损失规则：胜利 100%、失败存活损失 10-30%、失败死亡损失 60-90%
  - 结算画面（end_screen）显示：损失描述、污染能量、素材带出列表
  - 资源自动入账 `GameManager.materials`
- **实体场景化**（Mark S 完成）：
  - 10 个纯代码实体已转为 .tscn 场景文件
  - 所有 `Node2D.new() + set_script()` 改为 `load().instantiate() + setup()`
  - 涉及：auto_turret / decoy_drone / repair_beacon / grav_trap / fire_zone /
    cryo_zone / radio_blink_circle / bomber_explosion_effect / spitter_projectile / spore_projectile
- **独立关卡场景**（阶段13新增，Mark L 扩大）：
  - LevelDesert：开阔沙漠，19200×10800（LevelTest ~10 倍），用于 recon_patrol/salvage_run
  - LevelContaminated：污染带，19200×10800 双区域 + 4 个环境毒雾区，用于 containment/extermination/outpost_defense/high_risk_sweep
  - LevelTest 保留用于 titan_hunt/hive_assault（需 Boss + Region3）
- **配件解锁系统**（Mark E.1 完成）：
  - 配件默认锁定，需在任务中选取过一次该配件升级后自动解锁
  - 解锁记录持久化到 `unlocked_parts["配件"]`（存档已支持）
  - CarEditor 显示锁定图标 + 解锁条件文本
  - 结算画面显示新解锁的配件名称（金色高亮）
  - 未解锁配件不允许装备
- **NPC 对话进度追踪**（阶段14.2 完成）：
  - `GameManager.npc_dialogues` 追踪每个 NPC 的对话序列索引
  - `DialogueRunner` 新增 `npc_id` 配置项，对话结束后自动推进
  - 军营 NPC 使用对话序列：intro → day2 → day3 → idle（循环最后一条）
  - 存档持久化 NPC 对话进度
- **场景路由**：`MissionData.MISSION_SCENE_MAP` 按任务 ID 映射到关卡场景
- **素材掉落多样化**（Mark B 前置）：
  - 沙漠关卡：SandScarab/DuneBeetle 掉落甲虫甲壳(scarab_chitin)，RustHulk 掉落废金属(scrap_metal)
  - 污染关卡：BloatTick 掉落生物样本(bio_sample)，SporeCaster 掉落孢子样本(spore_sample)，AcidSpitter 掉落酸液腺(acid_gland)
  - 掉落使用 `enemy_filter` 按敌人类名过滤
- **精英波事件**：
  - 沙漠敌人管理器：每 10 个 arena_difficulty 触发精英波（2+ 只精英）
  - 污染敌人管理器：每 8 个 arena_difficulty 触发精英波（3+ 只精英）
- **存档系统加固**：SaveData.load_game 使用 `.get()` 容错，兼容缺失字段
- **代码健康度清理**（Mark D，2026-02-19）：
  - 删除孤立场景 `Contamination/`、`SalvageRun/`（早期原型，有脚本引用错误）
  - 修复 4 处 `:=` 违规（`player.gd`、`SaveData.gd`×2、`upgrade_screen.gd`）
  - 清理 `player.gd` 中 7+ 处 debug print、死代码分支、注释动画代码
- **升级扩充第三批**（阶段15，2026-02-19）：
  - 17 个升级（升级合集遗留8 + 扩充清单v1 B区9）数据entry + config + 图标映射
  - stat类gameplay效果已实现（暴击率/穿透/射速/伤害修正等）
  - 9 个复杂运行时机制升级待后续

### 关键架构决策
1. **MissionData 是纯数据**：不含逻辑参数（params/trigger），只存显示文本
2. **ObjectiveManager 管逻辑**：每个关卡场景树下放一个 ObjectiveManager 节点
3. **场景树优先**：尽量用 .tscn 子节点 + @onready，减少 new()+add_child()
4. **EnemyRank 枚举**：替代 is_elite/is_boss 布尔值 + scale 判定

### 重要文件路径
| 用途 | 路径 |
|------|------|
| 关卡配置表 | `Scripts/MissionData.gd` |
| 全局管理器 | `Scripts/Managers/gameManager.gd` |
| 升级管理器 | `scenes/manager/upgrade_manager.gd` |
| 升级数据定义 | `Scripts/AbilityUpgradeData.gd` |
| 目标管理器 | `scenes/manager/objective_manager.gd` |
| 目标 HUD | `scenes/ui/objective_hud.gd` |
| 地图场景 | `scenes/ui/mission_map.gd` + `.tscn` |
| 军营场景 | `scenes/Levels/MilitaryCamp/MilitaryCamp.gd` |
| 关卡基类 | `scenes/Levels/base_level.gd` |
| 测试关卡 | `scenes/Levels/LevelTest/LevelTest.gd` + `.tscn` |
| 沙漠关卡 | `scenes/Levels/LevelDesert/level_desert.gd` + `.tscn` |
| 污染关卡 | `scenes/Levels/LevelContaminated/level_contaminated.gd` + `.tscn` |
| 敌人管理器(测试) | `scenes/Levels/LevelTest/level_test_enemy_manager.gd` |
| 敌人管理器(沙漠) | `scenes/Levels/LevelDesert/desert_enemy_manager.gd` |
| 敌人管理器(污染) | `scenes/Levels/LevelContaminated/contaminated_enemy_manager.gd` |
| 玩家脚本 | `scenes/game_object/player/player.gd` |
| 武器处理 | `Scripts/WeaponUpgradeHandler.gd` |
| 存档 | `Scripts/Save/SaveData.gd` |
| 收集物 | `scenes/game_object/collectible/collectible.gd` + `.tscn` |
| 收集物掉落组件 | `scenes/component/collectible_drop_component.gd` |
| 防守据点 | `scenes/game_object/defend_outpost/defend_outpost.gd` + `.tscn` |
| 素材库字段 | `GameManager.materials` (SaveData 已持久化) |
| 结算画面 | `scenes/ui/end_screen.gd` |
| Debug 控制台 | `scenes/autoload/debug_console.gd` |
| 对话系统 | `scenes/autoload/dialogue_runner.gd` |
| 对话气泡 | `Dialogues/DialogueBalloon.gd` + `.tscn` |
| 对话数据 | `DialogueData/*.dialogue` |

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

## 下一步
### 阶段 14 续
- 14.3 主线/支线目标系统 UI 展示与奖励发放
- 14.4 剧情推进触发（章节完成条件）

### 阶段 15 遗留（复杂运行时机制）
9 个升级已有数据entry+config+图标，但gameplay效果需底层系统支持：
- `suppressive_net`（命中计数）、`stable_platform`（移动射击判定）、`multi_feed`（射击计数）
- `precision_bore`（暴击穿深hook）、`detonation_link`（暴击击杀AoE）、`shock_fragment`（穿透破片）
- `fallback_firing`（未命中检测）、`thermal_bolt`（连续暴击追踪）、`breach_equip`（碰撞伤害）

### 待实现的重要 Mark
- **Mark S**：✅ 已完成 — 10 个纯代码实体已转为 .tscn 场景化
- **Mark C**：✅ 已完成 — 任务结算与带出物品系统
- **Mark L**：✅ 已完成 — 关卡规模扩大到 19200×10800（LevelTest ~10 倍），任务时间 ~10 分钟
- **Mark E.1**：✅ 已完成 — 配件解锁系统（局内选取自动解锁 + CarEditor 锁定显示）
- **Mark E.2**：装备/预制造 + 出击资源检查（详见 ROADMAP + 策划书 5B）
- **Mark E.3**：配件预升级
- **Mark X**：玩家升级与怪物经验掉落重做（待用户描述后实现）
- **Mark T**：✅ 已完成 — 科技处废除
- **Mark D**：✅ 已完成 — 代码健康度清理（孤立场景删除、`:=` 修复、debug print 清理）

### 已知问题与注意事项
- 3 个升级 (`windmill_spread`、`windmill_speed`、`mine_multi_deploy`) 在 `UpgradeEffectManager` 中无配置，但由各自控制器/WeaponUpgradeHandler 直接处理，无运行时错误
- 9 个阶段15升级的gameplay效果待实现（数据/图标已就位）
- 62 个后置专属升级缺少图标（详见 `DOCUMENTS/HANDOFFS/UPGRADE_ICON_DRAWING.md`）
- `titan_hunt`/`hive_assault` 任务无独立场景，fallback 到 LevelTest（设计上为 Boss 关卡，依赖 Region3 机制，保留合理）

## 编码规范速查
1. **禁止 `:=`**：一律 `var x: Type = expr`
2. **禁止 preload 自身 .tscn**：用 `load()` 替代
3. **不考虑存档兼容**：改了就改了
4. **EnemyRank 枚举**：不用布尔值、不用 scale 判定
5. **敌人命名**：沙漠末世主题（污染生物/机械残骸）
6. **场景树优先**：尽量在 .tscn 中添加子节点，用 @onready 引用
