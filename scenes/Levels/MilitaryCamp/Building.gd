extends Node2D
class_name Building

@export var margin: int = 10
@export var image: Area2D

func can_interact(player: CharacterBody2D) -> bool:
	return image.overlaps_body(player)
