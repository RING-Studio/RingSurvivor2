extends Node

@export var end_screen_scene: PackedScene

var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")


func _ready():
	GameManager.start_mission()
	$%Player.health_component.died.connect(on_player_died)
	Transitions.transition(Transitions.transition_type.Diamond, true)
	setup_region_detection()
	
	# 初始化升级池（根据当前装备状态）
	var upgrade_manager = get_node_or_null("UpgradeManager")
	if upgrade_manager:
		# 添加主武器专属强化到池中
		var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
		var main_weapon_id = vehicle_config.get("主武器类型", null)
		if main_weapon_id != null:
			upgrade_manager._add_exclusive_upgrades_for_weapon(main_weapon_id)
		# 开始新对局
		upgrade_manager.start_session()


func setup_region_detection():
	"""设置区域检测信号连接"""
	var regions_node = $Regions
	var enemy_manager = $EnemyManager
	
	# 连接所有 Region1_x 区域
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region1_" + str(i))
		if region:
			region.body_entered.connect(_on_region1_entered)
			region.body_exited.connect(_on_region1_exited)
	
	# 连接所有 Region2_x 区域
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region2_" + str(i))
		if region:
			region.body_entered.connect(_on_region2_entered)
			region.body_exited.connect(_on_region2_exited)
	
	# 连接 Region3
	var region3 = regions_node.get_node_or_null("Region3")
	if region3:
		region3.body_entered.connect(_on_region3_entered)
		region3.body_exited.connect(_on_region3_exited)


func _on_region1_entered(body):
	"""玩家进入 Region1_x 区域"""
	if body.is_in_group("player"):
		var enemy_manager = $EnemyManager
		enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_1)


func _on_region1_exited(body):
	"""玩家离开 Region1_x 区域"""
	if body.is_in_group("player"):
		# 检查是否还在其他 Region1_x 中
		var regions_node = $Regions
		var still_in_region1 = false
		for i in range(1, 5):
			var region = regions_node.get_node_or_null("Region1_" + str(i))
			if region and region.has_overlapping_bodies():
				for overlapping_body in region.get_overlapping_bodies():
					if overlapping_body.is_in_group("player"):
						still_in_region1 = true
						break
				if still_in_region1:
					break
		
		if not still_in_region1:
			# 检查是否在其他区域中
			check_current_region()


func _on_region2_entered(body):
	"""玩家进入 Region2_x 区域"""
	if body.is_in_group("player"):
		var enemy_manager = $EnemyManager
		enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_2)


func _on_region2_exited(body):
	"""玩家离开 Region2_x 区域"""
	if body.is_in_group("player"):
		# 检查是否还在其他 Region2_x 中
		var regions_node = $Regions
		var still_in_region2 = false
		for i in range(1, 5):
			var region = regions_node.get_node_or_null("Region2_" + str(i))
			if region and region.has_overlapping_bodies():
				for overlapping_body in region.get_overlapping_bodies():
					if overlapping_body.is_in_group("player"):
						still_in_region2 = true
						break
				if still_in_region2:
					break
		
		if not still_in_region2:
			# 检查是否在其他区域中
			check_current_region()


func _on_region3_entered(body):
	"""玩家进入 Region3 区域"""
	if body.is_in_group("player"):
		var enemy_manager = $EnemyManager
		enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_3)
		# 触发 BOSS 生成（如果未生成）
		if not enemy_manager.boss_spawned:
			enemy_manager.spawn_boss()


func _on_region3_exited(body):
	"""玩家离开 Region3 区域"""
	if body.is_in_group("player"):
		# 检查是否还在其他区域中
		check_current_region()


func check_current_region():
	"""检查玩家当前所在的区域（优先级：Region3 > Region2 > Region1）"""
	var regions_node = $Regions
	var player = get_tree().get_first_node_in_group("player")
	var enemy_manager = $EnemyManager
	if not player:
		enemy_manager.set_current_region(enemy_manager.RegionType.NONE)
		return
	
	# 优先级检查：Region3 > Region2 > Region1
	var region3 = regions_node.get_node_or_null("Region3")
	if region3 and region3.has_overlapping_bodies():
		for overlapping_body in region3.get_overlapping_bodies():
			if overlapping_body.is_in_group("player"):
				enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_3)
				return
	
	# 检查 Region2_x
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region2_" + str(i))
		if region and region.has_overlapping_bodies():
			for overlapping_body in region.get_overlapping_bodies():
				if overlapping_body.is_in_group("player"):
					enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_2)
					return
	
	# 检查 Region1_x
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region1_" + str(i))
		if region and region.has_overlapping_bodies():
			for overlapping_body in region.get_overlapping_bodies():
				if overlapping_body.is_in_group("player"):
					enemy_manager.set_current_region(enemy_manager.RegionType.REGION_TYPE_1)
					return
	
	# 不在任何区域中
	enemy_manager.set_current_region(enemy_manager.RegionType.NONE)

# ========== 暂停 ==========
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(pause_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()


func on_player_died():
	if not GameManager.apply_mission_result("defeat"):
		return
	GlobalSaveData.save_game()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()
