extends Control

func _on_player_death():
	$ColorRect.visible = true
	$ColorRect/AnimationPlayer.play("fade_to_black")
