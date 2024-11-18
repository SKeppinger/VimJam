extends StaticBody2D

var active = true

func _process(_delta):
	if is_in_group("paused"):
		active = false
	else:
		active = true

func _on_area_2d_body_entered(body):
	if active and body.name == "Player":
		body.die()
