# 交接文档 — 供下次对话使用

更新日期：2026-02-15

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

## 当前完成状态（截至阶段 12）

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
| 测试关卡 | `scenes/Levels/LevelTest/LevelTest.gd` + `.tscn` |
| 敌人管理器 | `scenes/Levels/LevelTest/level_test_enemy_manager.gd` |
| 玩家脚本 | `scenes/game_object/player/player.gd` |
| 武器处理 | `Scripts/WeaponUpgradeHandler.gd` |
| 存档 | `Scripts/Save/SaveData.gd` |
| 收集物 | `scenes/game_object/collectible/collectible.gd` + `.tscn` |
| 收集物掉落组件 | `scenes/component/collectible_drop_component.gd` |
| 防守据点 | `scenes/game_object/defend_outpost/defend_outpost.gd` + `.tscn` |
| 素材库字段 | `GameManager.materials` (SaveData 已持久化) |
| 结算画面 | `scenes/ui/end_screen.gd` |

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

## 下一步（阶段 13）
参见 ROADMAP.md 阶段 13：
- 创建 2~3 个独立关卡场景（不同地形/区域/敌人组合）
- 每个场景配置自己的 ObjectiveManager 目标
- 场景内特殊机制

### 待实现的重要 Mark
- **Mark S**：10 个纯代码实体需要改为 .tscn 场景化（详见 ROADMAP）
- **Mark C**：任务结算与带出物品系统（背景设定、损失规则、升级返还，详见 ROADMAP + 策划书 5A）
- **Mark E**：配装系统进阶（解锁条件 → 装备/预制造 → 出击结算，详见 ROADMAP + 策划书 5B）
- **Mark T**：科技处废除 ✅ 已完成

## 编码规范速查
1. **禁止 `:=`**：一律 `var x: Type = expr`
2. **禁止 preload 自身 .tscn**：用 `load()` 替代
3. **不考虑存档兼容**：改了就改了
4. **EnemyRank 枚举**：不用布尔值、不用 scale 判定
5. **敌人命名**：沙漠末世主题（污染生物/机械残骸）
6. **场景树优先**：尽量在 .tscn 中添加子节点，用 @onready 引用
