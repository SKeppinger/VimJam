extends Control

func _on_player_death():
	$ColorRect.visible = true
	$ColorRect/AnimationPlayer.play("fade_to_black")


func _on_button_pressed() -> void:
	get_tree().reload_current_scene();
