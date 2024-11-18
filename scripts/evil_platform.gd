extends StaticBody2D

var active = true

var sprite
var area

# Sprites
var default_sprite = load("res://assets/evil_platform.png")
var deactive_sprite = load("res://assets/evil_platform_deactivated.png")

func _ready():
	sprite = $Sprite2D
	area = $Area2D

func _process(_delta):
	if is_in_group("paused"):
		active = false
		sprite.texture = deactive_sprite
		set_collision_layer_value(1, false)
		area.set_collision_mask_value(1, false)
	else:
		active = true
		sprite.texture = default_sprite
		set_collision_layer_value(1, true)
		area.set_collision_mask_value(1, true)

func _on_area_2d_body_entered(body):
	if active and body.name == "Player":
		body.die()
