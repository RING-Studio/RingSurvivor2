# 升级图标绘图交接文档

**用途**：下次新增升级选项后，按本文档规范绘制 icon 并接入项目。  
**相关**：`Scripts/AbilityUpgradeData.gd` 中的 `upgrade_icons` 字典、`Assets/Upgrades` 目录。

---

## 1. 流程概览

1. 在 `AbilityUpgradeData.entries` 中确认新升级的 `id`
2. 按风格规范绘制 icon，保存为 `Assets/Upgrades/{id}.png`
3. 在 `AbilityUpgradeData.upgrade_icons` 中新增 `"{id}": preload("res://Assets/Upgrades/{id}.png")`

---

## 2. 风格规范（必须统一）

- **整体**：像素风（pixel art），可见像素颗粒，方形构图，**无文字**
- **边框**：深色金属框（dark metallic frame），四角有铆钉/螺栓（rivets/bolts），类似 HUD 面板
- **背景**：框内为深蓝灰色（dark navy-gray）背景
- **主体**：居中、单一主体物，军事/机械主题；配色以钢灰、枪铁色为主，红/金/蓝等作强调色
- **禁止**：空白白边、与边框脱节的留白；背景框需统一

**参考图**：`Assets/Upgrades/external_missile.png`（外挂导弹）为边框标准。

---

## 3. 绘图描述模板（GenerateImage / AI 绘图）

每张图使用同一风格前缀 + 本升级主体描述：

```
Pixel art game upgrade icon for a military vehicle survival game. Style: pixel art with visible pixels, dark metallic frame border with rivets/bolts at corners (like a HUD panel), dark navy-gray interior background. Subject: [本升级的视觉主体，如：导弹、地雷、护盾等]. Represents "[升级英文名或含义]". Military/mechanical theme. Square format, no text.
```

**示例（外挂导弹）**：
```
Subject: A single sleek guided missile pointed upward-right, metallic silver body, red warhead tip, small stabilizer fins in gold/brass, trail of exhaust behind. Represents "External Missile".
```

---

## 4. 输出与命名

- **目录**：`Assets/Upgrades`
- **文件名**：`{升级ID}.png`（全小写、下划线，与 `AbilityUpgradeData.entries` 中的 `id` 完全一致）

---

## 5. 生成图标的存放与复制

- 绘图工具默认输出到 Cursor 项目 assets 目录
- 可使用 `Assets/Upgrades/copy_icons_from_cursor.ps1` 批量复制到项目：
  ```powershell
  cd d:\tools\godot\Projects\RingSurvivor2\Assets\Upgrades
  .\copy_icons_from_cursor.ps1
  ```
- 或手动将 `{id}.png` 放入 `Assets/Upgrades` 目录

---

## 6. 接入代码

在 `Scripts/AbilityUpgradeData.gd` 的 `upgrade_icons` 字典中添加：

```gdscript
"{新升级id}": preload("res://Assets/Upgrades/{新升级id}.png"),
```

`get_icon(upgrade_id)` 会据此返回对应图标，未配置的 id 返回 `null`。

---

## 7. 图标审计报告（2026-02-19 确认）

### 7.1 已完成：有代码 entry + 有 PNG + 有 upgrade_icons 映射（103 个）

`AbilityUpgradeData.upgrade_icons` 字典中的所有 103 个 ID 均已完成。
对应 PNG 文件在 `Assets/Upgrades/` 下存在且可被 Godot preload。

### 7.2 磁盘有 PNG 但代码无 entry（17 个）

以下 17 个升级在文档中有设计、图标已画好（PNG 存在于 `Assets/Upgrades/`），
但 `AbilityUpgradeData.entries` 中**尚无对应条目**，`upgrade_icons` 字典也未引用：

| PNG 文件 | 来源文档 | 说明 |
|----------|----------|------|
| `thermal_imager.png` | 升级合集 | 通用强化：热成像仪 |
| `laser_rangefinder.png` | 升级合集 | 通用强化：激光测距仪 |
| `sap_round.png` | 升级合集 | 通用强化：碎甲弹 |
| `extra_ammo_rack.png` | 升级合集 | 通用强化：额外弹药架 |
| `long_barrel.png` | 升级合集 | 主武器强化：加长炮管 |
| `tandem_heat.png` | 升级合集 | 主武器强化：串联破甲 |
| `breach_equip.png` | 升级合集 | 配件：破障器具 |
| `mg_programmed.png` | 升级合集 | 机炮专属：程控引爆 |
| `suppressive_net.png` | 升级扩充清单v1 | 主武器强化：压制网 |
| `ammo_belt.png` | 升级扩充清单v1 | 主武器强化：弹链供弹 |
| `stable_platform.png` | 升级扩充清单v1 | 主武器强化：稳定平台 |
| `multi_feed.png` | 升级扩充清单v1 | 主武器强化：多路供弹 |
| `precision_bore.png` | 升级扩充清单v1 | 主武器强化：精准膛线 |
| `detonation_link.png` | 升级扩充清单v1 | 主武器强化：引爆链路 |
| `shock_fragment.png` | 升级扩充清单v1 | 主武器强化：冲击破片 |
| `fallback_firing.png` | 升级扩充清单v1 | 主武器强化：备用射击 |
| `thermal_bolt.png` | 升级扩充清单v1 | 主武器强化：热能弹 |

> **处理方式**：待实现这 17 个升级的代码 entry 后，将 PNG 接入 `upgrade_icons` 字典。

### 7.3 有代码 entry 但无 PNG 无图标（62 个）— 需绘制

以下 62 个升级在 `AbilityUpgradeData.entries` 中有条目，但 `Assets/Upgrades/` 下
**没有对应 PNG 文件**，`upgrade_icons` 字典也未引用。全部为阶段 9 后置专属强化。

**地雷/烟雾/无线电/导弹后置**：无（mine_range 等旧后置已有图标）

**冷却装置后置（2）**：
`cooling_share`、`cooling_safeguard`

**无线电/激光/导弹/纤维/爆反/红外后置（12）**：
`radio_barrage_count`、`laser_focus`、`laser_overheat_cut`、`spall_reload`、`spall_reserve`、`era_rearm`、`era_shockwave`、`missile_warhead`、`ir_wideband`、`ir_lockbreak`、`decoy_duration`、`decoy_count`

**炮塔/EMP/信标/护盾/线圈后置（12）**：
`turret_rate`、`turret_pierce`、`emp_duration`、`emp_radius`、`beacon_heal`、`beacon_uptime`、`shield_capacity`、`shield_regen`、`coil_chain_count`、`coil_damage`

**冷凝/燃烧/酸蚀/轨道/喷雾/引力后置（12）**：
`cryo_slow`、`cryo_duration`、`fire_duration`、`fire_damage`、`acid_armor_break`、`acid_spread`、`orbital_delay_cut`、`orbital_damage`、`med_tick_rate`、`med_radius`、`grav_pull`、`grav_duration`

**集束/箔条/热焰/纳米/燃料/兴奋后置（12）**：
`cluster_count`、`cluster_radius`、`chaff_density`、`chaff_duration`、`flare_count`、`flare_cooldown`、`nano_repair_rate`、`nano_overcap`、`fuel_boost`、`fuel_efficiency`、`stim_trigger_hp`、`stim_duration`

**声呐/弹道/干扰/无人机/霰雷/回收/屏障后置（14）**：
`sonar_range`、`sonar_expose_bonus`、`ballistic_accuracy`、`ballistic_aoe`、`jammer_radius`、`jammer_intensity`、`uav_bomb_rate`、`uav_laser_tag`、`grapeshot_pellets`、`grapeshot_cone`、`scrap_drop_rate`、`scrap_value`、`barrier_angle`、`barrier_reflect`

> **处理方式**：按本文档 §2-§3 的风格规范与绘图模板，为每个 ID 绘制图标，保存为 `Assets/Upgrades/{id}.png`，然后在 `upgrade_icons` 字典中添加 preload。
>
> **建议**：后置专属图标可复用父配件图标的视觉元素 + 加上差异化标记（如 + 号、箭头、颜色偏移），以体现"强化"关系且避免 62 张完全独立设计。
