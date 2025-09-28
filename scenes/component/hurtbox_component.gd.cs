
using System;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public class D:\Workshop\Godot\2DSurvivorsCourse\scenes\component\hurtbox_component.gd : Area2D
{
	 
	public signal hit
	
	@export Node healthComponent
	
	public __TYPE floatingTextScene = GD.Load("res://scenes/ui/floating_text.tscn");
	
	
	public void _Ready()
	{  
		areaEntered.Connect(onAreaEntered);
	
	
	}
	
	public void OnAreaEntered(Area2D otherArea)
	{  
		if(!other_area is HitboxComponent)
		{
			return;
		
		}
		if(healthComponent == null)
		{
			return;
		
		}
		var hitboxComponent = otherArea as HitboxComponent;
		healthComponent.Damage(hitboxComponent.damage);
		
		var floatingText = floatingTextScene.Instantiate() as Node2D;
		GetTree().GetFirstNodeInGroup("foreground_layer").AddChild(floatingText);
		
		floatingText.global_position = globalPosition + (Vector2.UP * 16);
		
		string formatString = "%0.1f";
		if(Mathf.Round(hitboxComponent.damage) == hitboxComponent.damage)
		{
			formatString = "%0.0f";
		}
		floatingText.Start(formatString % hitboxComponent.damage);
		
		hit.Emit();
	
	
	}
	
	
	
}