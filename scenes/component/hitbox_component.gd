extends Area2D
class_name HitboxComponent

var damage = 0
var damage_type: String = "weapon"

signal hit_applied(target: Node, damage: float, damage_type: String)
