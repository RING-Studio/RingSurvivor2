# 升级图标绘制交接文档

**更新日期**：2026-02-21
**用途**：在新对话中为 Ring Survivor 2 的升级选项绘制/重绘统一风格 icon。
**相关文件**：`Scripts/AbilityUpgradeData.gd` 中的 `upgrade_icons` 字典、`Assets/Upgrades/` 目录。

---

## 0. 当前进度

| 批次 | 描述 | 总数 | 状态 |
|------|------|------|------|
| **第一批** | §4.1 Godot 导入失败图标 | 32 | **已完成** — 已绘制、复制到项目、`upgrade_icons` 已全部 `preload` |
| **第二批** | §4.2 后置专属强化图标 | 62 | **待绘制** — 无 PNG、`upgrade_icons` 中无条目 |
| **第三批** | §4.3 现有图标风格审查 | 88 | **待审查** — PNG 存在，需检查风格一致性后决定是否重绘 |

**下次开始时从第二批（§4.2）继续。**

---

## 1. 风格规范（必须严格统一）

### 1.1 参考图（以这 3 张为绝对标准）

- `Assets/Upgrades/addon_armor.png` — 附加装甲
- `Assets/Upgrades/ammo_belt.png` — 弹链供弹
- `Assets/Upgrades/armor_breaker.png` — 破甲弹

**新绘制的图标背景板、边框必须与这 3 张完全一致。**

### 1.2 风格要素

| 要素 | 要求 |
|------|------|
| **整体** | 像素风（pixel art），可见像素颗粒，方形构图，**无文字** |
| **边框** | 深色金属框（dark metallic frame），四角有铆钉/螺栓（rivets/bolts），类似 HUD 面板 |
| **背景** | 框内为深蓝灰色（dark navy-gray）背景 |
| **主体** | 居中、单一主体物，军事/机械主题；配色以钢灰、枪铁色为主，红/金/蓝等作强调色 |
| **禁止** | 空白白边、与边框脱节的留白；不允许文字 |

---

## 2. 绘图提示词模板

每张图使用**完全相同的风格前缀** + 本升级的主体描述。同时**附带参考图**以保证背景板一致：

```
Pixel art game upgrade icon for a military vehicle survival game.
Style: pixel art with visible pixels, dark metallic frame border with rivets/bolts at corners (like a HUD panel), dark navy-gray interior background.
Subject: [此处写本升级的视觉主体].
Represents "[升级含义]".
Military/mechanical theme. Square format, no text.
```

**GenerateImage 调用示例**：
```
GenerateImage(
  description: "Pixel art game upgrade icon for a military vehicle survival game. Style: pixel art with visible pixels, dark metallic frame border with rivets/bolts at corners (like a HUD panel), dark navy-gray interior background. Subject: A heavy ammunition belt feeding into a rotary mechanism, brass and copper cartridges in metallic links, feed mechanism visible. Represents \"Ammo Belt\". Military/mechanical theme. Square format, no text.",
  filename: "ammo_belt.png",
  reference_image_paths: [
    "d:\\tools\\godot\\Projects\\RingSurvivor2\\Assets\\Upgrades\\addon_armor.png",
    "d:\\tools\\godot\\Projects\\RingSurvivor2\\Assets\\Upgrades\\ammo_belt.png",
    "d:\\tools\\godot\\Projects\\RingSurvivor2\\Assets\\Upgrades\\armor_breaker.png"
  ]
)
```

---

## 3. 执行流程（重要！必须严格遵守）

### 3.1 速率限制

**短时间内连续调用 GenerateImage 超过约 4 次会触发绘图插件临时封禁，导致后续绘制全部失败。** 因此必须使用以下节奏：

### 3.2 每轮操作（循环执行）

```
第 1 步：绘制 2 张图标（GenerateImage × 2）
第 2 步：执行 5 次独立的 1 分钟休眠（共 5 分钟冷却）
第 3 步：回到第 1 步，绘制下 2 张
```

### 3.3 休眠指令的正确写法

**必须逐条发送**，每次等上一条完成后再发下一条（不可并行、不可合并为单条 5 分钟命令）：

```
Shell(command: "Start-Sleep -Seconds 60", block_until_ms: 90000)  # 休眠 1/5
Shell(command: "Start-Sleep -Seconds 60", block_until_ms: 90000)  # 休眠 2/5
Shell(command: "Start-Sleep -Seconds 60", block_until_ms: 90000)  # 休眠 3/5
Shell(command: "Start-Sleep -Seconds 60", block_until_ms: 90000)  # 休眠 4/5
Shell(command: "Start-Sleep -Seconds 60", block_until_ms: 90000)  # 休眠 5/5
```

**关键**：
- 用 `Start-Sleep -Seconds 60`（Windows PowerShell 命令）
- `block_until_ms` 设为 `90000`（90 秒超时，留 30 秒余量）
- 每条 Shell 命令必须等前一条返回结果后才发下一条（**顺序执行，不可并行**）
- Shell 启动时会输出 conda 报错（`ImportError: DLL load failed`），这是环境问题，**不影响 `Start-Sleep` 的实际执行**，忽略即可

### 3.4 图标输出路径与复制

GenerateImage 生成的图片保存到 **Cursor 项目缓存目录**：
```
C:\Users\Administrator\.cursor\projects\d-tools-godot-Projects-RingSurvivor2\assets\{filename}.png
```

这**不是** Godot 项目目录。绘制完成后需要复制到 Godot 项目：

**方法一**：运行项目内的复制脚本
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "d:\tools\godot\Projects\RingSurvivor2\Assets\Upgrades\copy_icons_from_cursor.ps1"
```

**方法二**：手动逐文件复制
```powershell
cmd /c copy "C:\Users\Administrator\.cursor\projects\d-tools-godot-Projects-RingSurvivor2\assets\{id}.png" "d:\tools\godot\Projects\RingSurvivor2\Assets\Upgrades\{id}.png"
```

### 3.5 接入代码

复制完成后，修改 `Scripts/AbilityUpgradeData.gd` 中 `upgrade_icons` 字典：

- 对于已有 `null` 的条目，改为 `preload`：
```gdscript
"{id}": preload("res://Assets/Upgrades/{id}.png"),
```

- 对于 `upgrade_icons` 中**完全没有条目**的 ID（如第二批 62 个后置强化），需在字典中**新增**对应行。
  建议在字典末尾（`"thermal_bolt"` 之后、闭合 `}` 之前）按分组添加。

---

## 4. 需要绘制/重绘的图标清单

### 4.1 ~~Godot 导入失败（32 个）~~ — 已完成 ✅

> **2026-02-21 完成**：32 个图标已全部重绘、复制到 `Assets/Upgrades/`、`upgrade_icons` 已全部 `preload`。

<details>
<summary>点击展开已完成清单</summary>

windmill_spread, windmill_speed, mg_overload, mg_heavy_round, mg_he_round, tank_gun_penetration, missile_reload, mine_range, mine_multi_deploy, mine_anti_tank, smoke_range, smoke_duration, repair_beacon, shield_emitter, emp_pulse, grav_trap, thunder_coil, incendiary_canister, acid_sprayer, orbital_ping, med_spray, chaff_launcher, flare_dispenser, nano_armor, fuel_injector_module, adrenaline_stim, sonar_scanner, ballistic_computer_pod, jammer_field, grapeshot_pod, scrap_collector, kinetic_barrier

</details>

### 4.2 尚无图标（62 个后置专属强化）— 待绘制 🔴

这些升级在 `AbilityUpgradeData.entries` 中有条目但从未绘制过图标。`upgrade_icons` 中也**无对应条目**（绘制完成后需新增行）。

> **建议**：后置专属图标可复用父配件的视觉元素 + 加差异化标记（如 +号、箭头、颜色变化），体现"强化"关系。

| # | 分组 | ID 列表 | Subject 描述建议 |
|---|------|---------|-----------------|
| 1-2 | **冷却装置后置 (2)** | `cooling_share`, `cooling_safeguard` | Cooling device with shared/networked pipes; Cooling unit with safety redundancy gauges |
| 3 | **无线电后置 (1)** | `radio_barrage_count` | Radio antenna with multiple artillery shell icons, barrage pattern |
| 4-5 | **激光后置 (2)** | `laser_focus`, `laser_overheat_cut` | Focused laser beam with convergence lens; Laser unit with heat vents and cooling fins |
| 6-7 | **纤维内衬后置 (2)** | `spall_reload`, `spall_reserve` | Spall liner panel being reloaded/replaced; Stacked spare spall liner plates in reserve |
| 8-9 | **爆反后置 (2)** | `era_rearm`, `era_shockwave` | ERA block being rearmed with fresh charge; ERA detonation shockwave blast ring |
| 10 | **导弹后置 (1)** | `missile_warhead` | Missile warhead close-up, exposed explosive core, enlarged blast tip |
| 11-12 | **红外后置 (2)** | `ir_wideband`, `ir_lockbreak` | IR sensor with wide-angle scanning arc; IR jammer breaking targeting lock, disruption lines |
| 13-14 | **诱饵后置 (2)** | `decoy_duration`, `decoy_count` | Decoy drone with extended timer/clock; Multiple decoy drones deploying together |
| 15-16 | **炮塔后置 (2)** | `turret_rate`, `turret_pierce` | Auto turret with rapid-fire barrel blur; Auto turret with armor-piercing rounds, penetrating shells |
| 17-18 | **EMP 后置 (2)** | `emp_duration`, `emp_radius` | EMP device with extended pulse wave duration; EMP device with expanded radius rings |
| 19-20 | **信标后置 (2)** | `beacon_heal`, `beacon_uptime` | Repair beacon with enhanced green healing aura; Repair beacon with extended uptime clock |
| 21-22 | **护盾后置 (2)** | `shield_capacity`, `shield_regen` | Shield emitter with larger/thicker energy barrier; Shield emitter with regeneration arrows cycling |
| 23-24 | **线圈后置 (2)** | `coil_chain_count`, `coil_damage` | Tesla coil with multiple chain lightning branches; Tesla coil with intensified high-voltage arcs |
| 25-26 | **冷凝后置 (2)** | `cryo_slow`, `cryo_duration` | Cryo canister with intense frost slow effect; Cryo canister with lingering ice crystals, timer |
| 27-28 | **燃烧后置 (2)** | `fire_duration`, `fire_damage` | Incendiary with prolonged burning flame, timer; Incendiary with intensified white-hot flames |
| 29-30 | **酸蚀后置 (2)** | `acid_armor_break`, `acid_spread` | Acid dissolving heavy armor plating; Acid spray with widened dispersal cone |
| 31-32 | **轨道后置 (2)** | `orbital_delay_cut`, `orbital_damage` | Orbital beacon with shortened countdown, fast arrow; Orbital strike with amplified impact explosion |
| 33-34 | **喷雾后置 (2)** | `med_tick_rate`, `med_radius` | Med spray with rapid pulse heal indicators; Med spray with expanded coverage radius rings |
| 35-36 | **引力后置 (2)** | `grav_pull`, `grav_duration` | Gravity device with stronger inward pull arrows; Gravity field with extended duration timer |
| 37-38 | **集束后置 (2)** | `cluster_count`, `cluster_radius` | Cluster mine releasing more sub-munitions; Cluster mine sub-munition with larger blast rings |
| 39-40 | **箔条后置 (2)** | `chaff_density`, `chaff_duration` | Chaff cloud with denser metallic strip coverage; Chaff cloud lingering longer, timer overlay |
| 41-42 | **热焰后置 (2)** | `flare_count`, `flare_cooldown` | Multiple flares being ejected simultaneously; Flare launcher with fast reload mechanism |
| 43-44 | **纳米后置 (2)** | `nano_repair_rate`, `nano_overcap` | Nano-bots repairing at accelerated speed; Nano-bots generating excess shield overflow |
| 45-46 | **燃料后置 (2)** | `fuel_boost`, `fuel_efficiency` | Fuel injector with turbo boost flames; Fuel system with efficiency gauge in green zone |
| 47-48 | **兴奋后置 (2)** | `stim_trigger_hp`, `stim_duration` | Stimulant syringe with higher HP threshold marker; Stimulant syringe with extended effect timer |
| 49-50 | **声呐后置 (2)** | `sonar_range`, `sonar_expose_bonus` | Sonar device with extended detection range rings; Sonar with highlighted vulnerable target markers |
| 51-52 | **弹道后置 (2)** | `ballistic_accuracy`, `ballistic_aoe` | Ballistic computer with precision crosshair; Ballistic pod with expanded explosion radius |
| 53-54 | **干扰后置 (2)** | `jammer_radius`, `jammer_intensity` | Jammer with wider disruption field radius; Jammer with intensified signal distortion waves |
| 55-56 | **无人机后置 (2)** | `uav_bomb_rate`, `uav_laser_tag` | UAV dropping bombs rapidly, multiple bombs falling; UAV with laser designator beam on target |
| 57-58 | **霰弹后置 (2)** | `grapeshot_pellets`, `grapeshot_cone` | Grapeshot pod with more pellets scattering; Grapeshot with wider scatter cone angle |
| 59-60 | **回收后置 (2)** | `scrap_drop_rate`, `scrap_value` | Scrap collector with increased drop sparks; Scrap collector with larger/shinier scrap pieces |
| 61-62 | **屏障后置 (2)** | `barrier_angle`, `barrier_reflect` | Kinetic barrier with extended duration timer; Kinetic barrier reflecting incoming projectiles |

### 4.3 现有图标风格审查（88 个）— 可能需重绘

以下 88 个图标已存在于 `Assets/Upgrades/` 且 Godot 可导入。请先检查它们的风格是否与参考图（addon_armor / ammo_belt / armor_breaker）一致。如果背景板、边框、像素风格不统一，需要重绘。

<details>
<summary>点击展开完整列表</summary>

addon_armor, ammo_belt, armor_breaker, auto_turret, battle_awareness, bloodletting, breach_equip, breakthrough, breath_hold, burst_fire, cabin_ac, chain_fire, chaos_fire, christie_suspension, cluster_mine, cooling_device, crit_conversion, crit_damage, crit_rate, cryo_canister, damage_bonus, decoy_drone, detonation_link, emergency_repair, era_block, execution_protocol, external_missile, extra_ammo_rack, fallback_firing, fin_stabilized, fire_suppression, focus, gas_turbine, harvest, health, heat_sink, hot_load, howitzer_radius, howitzer_reload, hydro_pneumatic, ir_counter, kill_chain, kinetic_buffer, laceration, laser_rangefinder, laser_suppress, lethal_strike, long_barrel, mg_programmed, mine, mine_cooldown, missile_damage, missile_salvo, mobility_servos, multi_feed, overdrive_trigger, overpressure_limiter, overwatch_uav, penetration, precision_bore, radio_radius, radio_support, rapid_fire, recoil_compensator, reinforced_bulkhead, relief_valve, repair_kit, ricochet, sap_round, scatter_shot, sharpened, shock_core, shock_fragment, smoke_grenade, spall_liner, split_shot, spread_shot, stable_platform, suppressive_net, sweep_fire, tandem_heat, tank_gun_depth, target_computer, thermal_bolt, thermal_imager, tracer_rounds, weakpoint_strike, windmill

</details>

---

## 5. 优先级

1. ~~**第一批（32 个）**：§4.1 的 Godot 导入失败图标~~ — **已完成** ✅
2. **第二批（62 个）**：§4.2 的后置专属图标 — **下次从这里开始**
3. **第三批（审查）**：§4.3 风格不一致图标 — 如有偏差才重绘

---

## 6. 命名规则

- **目录**：`Assets/Upgrades/`
- **文件名**：`{升级ID}.png`（全小写、下划线，与 `AbilityUpgradeData.entries` 中的 `id` 完全一致）
- **格式**：PNG，确保 Godot 4.5.1 可导入

---

## 7. 参考文档

- 升级数据与 ID 定义：`Scripts/AbilityUpgradeData.gd`
- 升级合集文档：`DOCUMENTS/升级合集.md`
- Godot 导入失败的原始文件备份：`.trash/Assets_Upgrades_png/`
- 复制脚本：`Assets/Upgrades/copy_icons_from_cursor.ps1`

---

## 8. 快速启动

在新对话中说：

> 按 `DOCUMENTS/HANDOFFS/UPGRADE_ICON_DRAWING.md` 绘制升级图标，从第二批（§4.2 后置专属强化，62 个）开始。参考图为 `Assets/Upgrades/addon_armor.png`、`ammo_belt.png`、`armor_breaker.png`。请严格按照文档中的执行流程（每 2 张 + 5×1 分钟休眠）进行。绘制完成后需要在 `upgrade_icons` 字典中新增对应条目。
