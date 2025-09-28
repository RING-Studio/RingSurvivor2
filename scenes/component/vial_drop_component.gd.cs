
using System;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public class D:\Workshop\Godot\2DSurvivorsCourse\scenes\component\vial_drop_component.gd : Node
{
	 
	@export_range(0, 1) var float dropPercent = .5;
	@export Node healthComponent
	@export PackedScene vialScene
	
	
	public void _Ready()
	{  
		(healthComponent as HealthComponent).died.Connect(onDied);
	
	
	}
	
	public void OnDied()
	{  
		var adjustedDropPercent = dropPercent;
		var experienceGainUpgradeCount = MetaProgression.GetUpgradeCount("experience_gain");
		if(experienceGainUpgradeCount > 0)
		{
			adjustedDropPercent += .1;
		
		}
		if(GD.Randf() > adjustedDropPercent)
		{
			return;
		
		}
		if(vialScene == null)
		{
			return;
		
		}
		if(!owner is Node2D)
		{
			return;
		
		}
		var spawnPosition = (owner as Node2D).global_position;
		var vialInstance = vialScene.Instantiate() as Node2D;
		var entitiesLayer = GetTree().GetFirstNodeInGroup("entities_layer");
		entitiesLayer.AddChild(vialInstance);
		vialInstance.global_position = spawnPosition;
	
	
	}
	
	
	
}