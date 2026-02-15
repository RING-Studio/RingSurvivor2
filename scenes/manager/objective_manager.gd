extends Node
class_name ObjectiveManager
## 关卡内目标管理器 — 作为子节点放入关卡场景树
## 负责：目标状态管理、进度追踪、触发链、胜负判定
## 各关卡通过配置 @export 或在 _ready 中调用 add_objective() 来定义目标
## MissionData 不参与逻辑，它只存显示文本

signal all_primary_completed  # 所有主目标完成 → 胜利
signal primary_failed  # 任意主目标失败 → 败
signal objective_state_changed(obj_id: String, new_state: String)

# ========== 目标状态 ==========
# 每个目标是一个字典：
#   id: String
#   display_name: String
#   primary: bool
#   state: "hidden" / "active" / "completed" / "failed"
#   progress: int
#   target: int  (0 = 不计数)
#   timer: float (该目标激活后经过的时间)
#   time_limit: float (-1 = 无限)
#   after: String (前置目标 id，空 = 开局激活)
var _objectives: Array[Dictionary] = []
var _finished: bool = false
var _time_elapsed: float = 0.0


func _process(delta: float) -> void:
	if _finished:
		return

	_time_elapsed += delta

	for obj in _objectives:
		if obj["state"] != "active":
			continue
		obj["timer"] = obj["timer"] + delta

		# 时间到达检查
		var limit: float = obj["time_limit"]
		if limit > 0 and obj["timer"] >= limit:
			if obj["survive"]:
				# 生存类目标：达到时限 = 完成
				_set_state(obj, "completed")
			elif obj["primary"]:
				# 非生存主目标：达到时限 = 失败
				_set_state(obj, "failed")
			else:
				# 非生存次要目标：超时则标记失败（不影响全局）
				_set_state(obj, "failed")
			return


# ========== 添加目标 ==========

func add_objective(config: Dictionary) -> void:
	"""添加一个目标。config 字段：
	- id: String (必填)
	- display_name: String
	- primary: bool (默认 true)
	- target: int (计数目标值，0=不计数，如 reach_area)
	- time_limit: float (秒，-1=无限)
	- after: String (前置目标 id，空=开局激活)
	"""
	var obj: Dictionary = {
		"id": str(config.get("id", "")),
		"display_name": str(config.get("display_name", "")),
		"primary": bool(config.get("primary", true)),
		"state": "active",
		"progress": 0,
		"target": int(config.get("target", 0)),
		"timer": 0.0,
		"time_limit": float(config.get("time_limit", -1)),
		"survive": bool(config.get("survive", false)),  # true = 达到时限完成而非失败
		"after": str(config.get("after", "")),
	}

	# 有前置目标时初始为 hidden
	if not obj["after"].is_empty():
		obj["state"] = "hidden"

	_objectives.append(obj)


# ========== 进度报告（由关卡中各系统调用） ==========

func report_progress(obj_id: String, amount: int = 1) -> void:
	"""通用进度报告：给指定目标增加计数"""
	if _finished:
		return
	var obj: Dictionary = _find(obj_id)
	if obj.is_empty() or obj["state"] != "active":
		return
	obj["progress"] = obj["progress"] + amount
	if obj["target"] > 0 and obj["progress"] >= obj["target"]:
		_set_state(obj, "completed")


func report_complete(obj_id: String) -> void:
	"""直接标记目标完成（如 reach_area / boss_kill）"""
	if _finished:
		return
	var obj: Dictionary = _find(obj_id)
	if obj.is_empty() or obj["state"] != "active":
		return
	_set_state(obj, "completed")


func report_fail(obj_id: String) -> void:
	"""直接标记目标失败（如据点被毁）"""
	if _finished:
		return
	var obj: Dictionary = _find(obj_id)
	if obj.is_empty() or obj["state"] != "active":
		return
	_set_state(obj, "failed")


# ========== 查询接口 ==========

func get_all_objectives() -> Array[Dictionary]:
	return _objectives

func get_objective(obj_id: String) -> Dictionary:
	return _find(obj_id)

func is_active(obj_id: String) -> bool:
	var obj: Dictionary = _find(obj_id)
	return obj.get("state", "") == "active"

func is_completed(obj_id: String) -> bool:
	var obj: Dictionary = _find(obj_id)
	return obj.get("state", "") == "completed"

func get_completed_secondary_ids() -> Array[String]:
	var result: Array[String] = []
	for obj in _objectives:
		if not obj["primary"] and obj["state"] == "completed":
			result.append(str(obj["id"]))
	return result

func get_time_elapsed() -> float:
	return _time_elapsed

func is_finished() -> bool:
	return _finished


# ========== 内部 ==========

func _find(obj_id: String) -> Dictionary:
	for obj in _objectives:
		if obj["id"] == obj_id:
			return obj
	return {}


func _set_state(obj: Dictionary, new_state: String) -> void:
	obj["state"] = new_state
	objective_state_changed.emit(obj["id"], new_state)

	if new_state == "completed":
		_unlock_after(obj["id"])
		if _all_primary_done():
			_finished = true
			all_primary_completed.emit()

	elif new_state == "failed" and obj["primary"]:
		_finished = true
		primary_failed.emit()


func _unlock_after(completed_id: String) -> void:
	"""解锁以 completed_id 为前置的隐藏目标"""
	for obj in _objectives:
		if obj["state"] == "hidden" and obj["after"] == completed_id:
			obj["state"] = "active"
			obj["timer"] = 0.0
			obj["progress"] = 0
			objective_state_changed.emit(obj["id"], "active")


func _all_primary_done() -> bool:
	for obj in _objectives:
		if not obj["primary"]:
			continue
		if obj["state"] == "hidden":
			# 隐藏的主目标 = 前置未完成，不算通过
			return false
		if obj["state"] != "completed":
			return false
	return true
