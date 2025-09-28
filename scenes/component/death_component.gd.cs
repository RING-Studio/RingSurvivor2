
using System;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public class D:\Workshop\Godot\2DSurvivorsCourse\scenes\component\death_component.gd : Node2D
{
	 
	@export Node healthComponent
	@export Sprite2D sprite
	
	
	public void _Ready()
	{  
		$GPUParticles2D.texture = sprite.texture;
		healthComponent.died.Connect(onDied);
		
	
	}
	
	public void OnDied()
	{  
		if(owner == null || !owner is Node2D)
		{
			return;
	
		}
		var spawnPosition = owner.global_position;
		
		var entities = GetTree().GetFirstNodeInGroup("entities_layer");
		GetParent().RemoveChild(this);
		entities.AddChild(this);
		
		globalPosition = spawnPosition;
		$AnimationPlayer.Play("default")
		$HitRandomAudioPlayerComponent.PlayRandom()
	
	
	}
	
	
	
}