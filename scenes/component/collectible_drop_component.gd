extends Node
class_name CollectibleDropComponent
## 收集物掉落组件 — 挂在敌人身上，敌人死亡时按概率掉落收集物
## 需要由关卡脚本在运行时配置（因为不同关卡/目标需要不同掉落）

@export var health_component: HealthComponent

## 掉落配置列表
## 每项: { "type": "energy_core", "color": Color(...), "drop_chance": 0.3 }
var drop_configs: Array[Dictionary] = []


func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_died)
	else:
		# 尝试从 owner 获取 HealthComponent
		if owner and owner.has_node("HealthComponent"):
			var hc: Node = owner.get_node("HealthComponent")
			if hc is HealthComponent:
				(hc as HealthComponent).died.connect(_on_died)


func add_drop(type: String, color: Color, drop_chance: float) -> void:
	"""添加一种掉落配置"""
	drop_configs.append({
		"type": type,
		"color": color,
		"drop_chance": clamp(drop_chance, 0.0, 1.0)
	})


func _on_died() -> void:
	if not owner is Node2D:
		return
	var spawn_pos: Vector2 = (owner as Node2D).global_position

	for config in drop_configs:
		if randf() > float(config.get("drop_chance", 0.0)):
			continue
		var type: String = str(config.get("type", "energy_core"))
		var color: Color = config.get("color", Color(0.2, 0.8, 1.0))
		# 轻微随机偏移避免重叠
		var offset: Vector2 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		Collectible.spawn_at(spawn_pos + offset, type, color, get_tree())
