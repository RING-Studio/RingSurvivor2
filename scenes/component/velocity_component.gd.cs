
using System;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public class D:\Workshop\Godot\2DSurvivorsCourse\scenes\component\velocity_component.gd : Node
{
	 
	@export int maxSpeed = 40;
	@export float acceleration = 5;
	
	public __TYPE velocity = Vector2.ZERO;
	
	
	public void AccelerateToPlayer()
	{  
		var ownerNode2D = owner as Node2D;
		if(ownerNode2D == null)
		{
			return;
		
		}
		var player = GetTree().GetFirstNodeInGroup("player") as Node2D;
		if(player == null)
		{
			return;
		
		}
		var direction = (player.global_position - ownerNode2D.global_position).Normalized();
		AccelerateInDirection(direction);
	
	
	}
	
	public void AccelerateInDirection(Vector2 direction)
	{  
		var desiredVelocity = direction * maxSpeed;
		velocity = velocity.Lerp(desiredVelocity, 1 - Mathf.Exp(-acceleration * GetProcessDeltaTime()));
	
	
	}
	
	public void Decelerate()
	{  
		AccelerateInDirection(Vector2.ZERO);
	
	
	}
	
	public void Move(CharacterBody2D characterBody)
	{  
		characterBody.velocity = velocity;
		characterBody.MoveAndSlide();
		velocity = characterBody.velocity;
	
	
	}
	
	
	
}