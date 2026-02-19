# 升级图标绘制交接文档

**用途**：在新对话中继续完成「为 Ring Survivor 2 所有升级选项绘制统一风格 icon」的工作。  
**参考历史**：`.specstory/history/2026-02-12_07-38Z-icon-design-for-project-upgrades.md`

---

## 1. 任务目标

- 为项目中**所有升级选项**绘制 icon（像素风、统一背景框）。
- 输出目录：**`Assets/Upgrades`**（Godot 项目内）。
- 文件名：**`{升级ID}.png`**，例如 `crit_rate.png`、`external_missile.png`。

若 `Assets/Upgrades` 中已存在某 `id.png`，可跳过该张，只补画缺失项。

---

## 2. 风格标准（必须统一）

以**外挂导弹（external_missile）**为参考：深色金属边框、无空白白边。

- **整体**：像素风（pixel art），可见像素颗粒，方形构图，**无文字**。
- **边框**：深色金属框（dark metallic frame），四角有铆钉/螺栓（rivets/bolts），类似 HUD 面板。
- **背景**：框内为深蓝灰色（dark navy-gray）背景。
- **主体**：居中、单一主体物，军事/机械主题；配色以钢灰、枪铁色为主，红/金/蓝等作强调色。
- **禁止**：不要出现空白白边或与边框脱节的留白；背景框要统一。

---

## 3. 绘图描述模板（GenerateImage / 绘图工具）

每张图使用同一段**风格前缀** + **本升级主体描述**：

```
Pixel art game upgrade icon for a military vehicle survival game. Style: pixel art with visible pixels, dark metallic frame border with rivets/bolts at corners (like a HUD panel), dark navy-gray interior background. Subject: [此处写本升级的视觉主体，如：一枚斜向上的导弹、银色弹体红色战斗部金色尾翼、尾焰]. Represents "[升级中文名或英文含义]". Military/mechanical theme. Square format, no text.
```

**示例（外挂导弹）**：  
Subject: A single sleek guided missile in center frame, pointed upward-right, metallic silver body, red warhead tip, small stabilizer fins in gold/brass, trail of exhaust behind. Represents "External Missile".

---

## 4. 待绘制图标完整列表

### 4.1 基础 100 项（通用 25 + 主武器 40 + 配件 35）

按 `DOCUMENTS/升级扩充清单v1.md` 与 `DOCUMENTS/升级合集.md` 的 ID 为准。

| 分类 | ID 列表 |
|------|--------|
| **通用强化 (25)** | `crit_rate`, `crit_damage`, `damage_bonus`, `health`, `heat_sink`, `repair_kit`, `cabin_ac`, `christie_suspension`, `gas_turbine`, `hydro_pneumatic`, `thermal_imager`, `laser_rangefinder`, `sap_round`, `extra_ammo_rack`, `addon_armor`, `relief_valve`, `long_barrel`, `tandem_heat`, `emergency_repair`, `reinforced_bulkhead`, `kinetic_buffer`, `overpressure_limiter`, `mobility_servos`, `target_computer`, `battle_awareness` |
| **主武器强化 (40)** | `rapid_fire`, `chain_fire`, `scatter_shot`, `burst_fire`, `sweep_fire`, `chaos_fire`, `windmill`, `breakthrough`, `fire_suppression`, `penetration`, `ricochet`, `spread_shot`, `split_shot`, `breath_hold`, `focus`, `harvest`, `lethal_strike`, `crit_conversion`, `hot_load`, `fin_stabilized`, `sharpened`, `bloodletting`, `laceration`, `armor_breaker`, `weakpoint_strike`, `overdrive_trigger`, `recoil_compensator`, `tracer_rounds`, `shock_core`, `execution_protocol`, `suppressive_net`, `ammo_belt`, `stable_platform`, `multi_feed`, `precision_bore`, `detonation_link`, `shock_fragment`, `kill_chain`, `fallback_firing`, `thermal_bolt` |
| **配件 (35)** | `mine`, `cooling_device`, `breach_equip`, `smoke_grenade`, `radio_support`, `laser_suppress`, `spall_liner`, `era_block`, `external_missile`, `ir_counter`, `decoy_drone`, `auto_turret`, `cluster_mine`, `emp_pulse`, `repair_beacon`, `shield_emitter`, `chaff_launcher`, `flare_dispenser`, `nano_armor`, `fuel_injector_module`, `adrenaline_stim`, `sonar_scanner`, `ballistic_computer_pod`, `jammer_field`, `overwatch_uav`, `incendiary_canister`, `cryo_canister`, `acid_sprayer`, `thunder_coil`, `grapeshot_pod`, `orbital_ping`, `scrap_collector`, `med_spray`, `grav_trap`, `kinetic_barrier` |

### 4.2 专属/衍生强化（需有图标）

| 分类 | ID 列表 |
|------|--------|
| **地雷专属** | `mine_range`, `mine_cooldown`, `mine_multi_deploy`, `mine_anti_tank` |
| **烟雾/无线电/导弹专属** | `smoke_range`, `smoke_duration`, `radio_radius`, `missile_damage` |
| **风车衍生** | `windmill_spread`, `windmill_speed` |
| **机炮专属** | `mg_overload`, `mg_heavy_round`, `mg_he_round`, `mg_programmed` |
| **榴弹炮专属** | `howitzer_reload`, `howitzer_radius` |
| **坦克炮专属** | `tank_gun_depth`, `tank_gun_penetration` |
| **导弹主武器专属** | `missile_salvo`, `missile_reload` |

合计：**100 + 4 + 4 + 2 + 4 + 2 + 2 + 2 = 120 个** 图标（与历史对话中统计一致）。

---

## 5. 上一轮对话进度（截止到用户请求交接时）

- **已完成生成**（在历史中可见 generate_image 成功）：  
  通用强化 1–25、主武器强化 26–约 64（到 `kill_chain`、`fallback_firing` 为止）。  
- **未在本轮生成**：  
  - 主武器：`thermal_bolt`  
  - 配件 66–100：`mine` 起至 `kinetic_barrier`  
  - 所有专属/衍生：地雷专属、烟雾/无线电/导弹专属、风车、机炮/榴弹/坦克/导弹主武器专属  

**注意**：历史中图片生成到 Cursor 项目 assets 目录，复制到 `Assets/Upgrades` 时可能未全部成功；当前若 `Assets/Upgrades` 为空或不全，可先列出已有 `*.png`，再只生成缺失的 `{id}.png` 并保存到 `d:\tools\godot\Projects\RingSurvivor2\Assets\Upgrades\`。

---

## 6. 建议执行流程

1. **检查现状**  
   - 列出 `Assets/Upgrades` 下已有 `*.png`。  
   - 可选：检查 Cursor 项目 assets 目录是否仍有历史生成的 png，若有可复制到 `Assets/Upgrades` 并统一命名为 `{id}.png`。

2. **补全缺失**  
   - 对上述完整列表中的每个 ID，若不存在 `Assets/Upgrades/{id}.png`，则：  
     - 按「风格标准」与「描述模板」编写 Subject/Represents；  
     - 调用绘图工具（如 GenerateImage）生成；  
     - 将输出保存为 `Assets/Upgrades/{id}.png`。

3. **批量策略**  
   - 每批 4–6 张并行生成，避免单次请求过长。  
   - 若遇限流，可适当间隔（历史中曾用 1 分钟间隔）。

4. **命名与放置**  
   - 文件名必须为 **`{id}.png`**，全部小写、下划线，与表格中 ID 完全一致。

---

## 7. 参考文档

- 升级数据与 ID：`DOCUMENTS/升级合集.md`、`DOCUMENTS/升级扩充清单v1.md`
- 对话历史与示例描述：`.specstory/history/2026-02-12_07-38Z-icon-design-for-project-upgrades.md`
- 现有参考图（风格参考）：`Assets/GPT` 下 ChatGPT 系列 png，以及以 **external_missile** 为边框标准

---

**交接完成**：在新 chat 中说明「按 DOCUMENTS/temp/UPGRADE_ICON_HANDOFF.md 继续画升级图标」，并沿用同一流程与绘图要求即可。
