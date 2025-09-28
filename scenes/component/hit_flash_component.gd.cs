
using System;
using Godot;
using Dictionary = Godot.Collections.Dictionary;
using Array = Godot.Collections.Array;


public class D:\Workshop\Godot\2DSurvivorsCourse\scenes\component\hit_flash_component.gd : Node
{
	 
	@export Node healthComponent
	@export Sprite2D sprite
	@export ShaderMaterial hitFlashMaterial
	
	public Tween hitFlashTween
	
	
	public void _Ready()
	{  
		healthComponent.health_decreased.Connect(onHealthDecreased);
		sprite.material = hitFlashMaterial;
		
	
	}
	
	public void OnHealthDecreased()
	{  
		if(hitFlashTween != null && hitFlashTween.IsValid())
		{
			hitFlashTween.Kill();
			
		}
		(sprite.material as ShaderMaterial).SetShaderParameter("lerp_percent", 1.0);
		hitFlashTween = CreateTween();
		hitFlashTween.TweenProperty(sprite.material, "shader_parameter/lerp_percent", 0.0, .25)\
		base.SetEase(Tween.EASE_IN).SetTrans(Tween.TRANS_CUBIC)
	
	
	}
	
	
	
}