extends CharacterBody2D

@export var arena_time_manager: Node

@export var rotation_speed: float = 4.0

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent

var enemys_in_contact = []

var number_colliding_bodies = 0
var base_speed = 0


func _ready():
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)
	base_speed = velocity_component.max_speed
	
	$CollisionArea2D.body_entered.connect(on_body_entered)
	$CollisionArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_decreased.connect(on_health_decreased)
	health_component.health_changed.connect(on_health_changed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	await get_tree().process_frame
	init_player_data()
	update_health_display()
	
func init_player_data():
	var health = GameManager.get_player_max_health()
	health_component.max_health = health
	health_component.current_health = health

	# 根据配装添加Ability
	setup_equipped_abilities()

func _process(delta):
	var rotation_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	rotation += rotation_input * rotation_speed * delta
	
	var move_input = Input.get_action_strength("up") - Input.get_action_strength("down")
	var direction = Vector2.ZERO
	if move_input != 0:
		direction = transform.x * sign(move_input)

	velocity_component.accelerate_in_direction(direction.normalized())
	velocity_component.move(self)
	
	# if move_input != 0:
	# 	# animation_player.play("walk")
	# 	pass
	# else:
	# 	# animation_player.play("RESET")
	# 	pass


func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
		return

	var damage: float = 0
	for body in enemys_in_contact:
		if body.is_in_group("enemy"):
			damage += GlobalFomulaManager.calculate_damage(body.base_damage,
														 body.hardAttackMultiplierPercent,
														 body.soft_attack_multiplier_percent,
														 body.hard_attack_depth_mm,
														 GameManager.get_player_armor_thickness(),
														 GameManager.get_player_armor_coverage(),
														 GameManager.get_player_armor_damage_reduction_percent())

			# print( body.name )
			# print("armor thickness:", body.armor_thickness)
			# print("armor coverage:", body.armorCoverage)
			# print("base damage:", body.base_damage)
			# print("soft attack multiplier percent:", body.soft_attack_multiplier_percent)
			# print("hard attack multiplier percent:", body.hardAttackMultiplierPercent)
			# print("hard attack depth mm:", body.hard_attack_depth_mm)

	print("enemy damage to player:", damage)
	health_component.damage(damage)
	damage_interval_timer.start()

func update_health_display():
	health_bar.value = health_component.get_health_percent()
	GameEvents.health_changed.emit(health_component.current_health, health_component.max_health)

func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1

	if enemys_in_contact.has(other_body):
		return
	enemys_in_contact.append(other_body)
	check_deal_damage()


func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1

	if enemys_in_contact.has(other_body):
		enemys_in_contact.erase(other_body)


func on_damage_interval_timer_timeout():
	check_deal_damage()


func on_health_decreased():
	GameEvents.emit_player_damaged()
	$HitRandomStreamPlayer.play_random()
	

func on_health_changed():
	update_health_display()
	
func on_ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	# if ability_upgrade is Ability:
	# 	var ability = ability_upgrade as Ability
	# 	abilities.add_child(ability.ability_controller_scene.instantiate())
	# elif ability_upgrade.id == "player_speed":
	# 	velocity_component.max_speed = base_speed + (base_speed * current_upgrades["player_speed"]["quantity"] * .1)

	print("-------------------")	
	print("基础伤害: " + str(GameManager.get_player_base_damage()))
	print("硬攻倍率: " + str(GameManager.get_player_hard_attack_multiplier_percent()))
	print("软攻倍率: " + str(GameManager.get_player_soft_attack_multiplier_percent()))
	print("硬攻深度: " + str(GameManager.get_player_hard_attack_depth_mm()))
	print("装甲厚度: " + str(GameManager.get_player_armor_thickness()))
	print("覆甲率: " + str(GameManager.get_player_armor_coverage()))
	print("击穿伤害减免: " + str(GameManager.get_player_armor_damage_reduction_percent()))
	print("-------------------")

func setup_equipped_abilities():
	"""根据当前车辆配装设置Ability"""
	var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
	if vehicle_config == null:
		return

	# 获取主武器类型
	var main_weapon_id = vehicle_config.get("主武器类型")
	if main_weapon_id == null:
		return

	# 根据武器ID添加对应的Ability Controller
	match main_weapon_id:
		1:  # 机炮
			var machine_gun_controller = preload("res://scenes/ability/machine_gun_ability_controller/machine_gun_ability_controller.tscn").instantiate()
			abilities.add_child(machine_gun_controller)
			print("已装备机炮")
		# 这里可以添加其他武器的case
		# 2:  # 榴弹炮
		# 3:  # 坦克炮
		# 4:  # 导弹

func on_arena_difficulty_increased(difficulty: int):
	var health_regeneration_quantity = MetaProgression.get_upgrade_count("health_regeneration")
	if health_regeneration_quantity > 0:
		var is_thirty_second_interval = (difficulty % 6) == 0
		if is_thirty_second_interval:
			health_component.heal(health_regeneration_quantity)
