extends StaticBody2D

@export var MOVE_DIR = 0
@export var SPEED = 0.0
@export var TRAVEL_TIME = 0.0

var sprite
var area

# Sprites
var default_sprite = load("res://assets/evil_platform.png")
var deactive_sprite = load("res://assets/evil_platform_deactivated.png")

var timer = 0.0
var active = false

func set_values(direc, sp, time):
	MOVE_DIR = direc
	SPEED = sp
	TRAVEL_TIME = time
	active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = $Sprite2D
	area = $Area2D
	print("projectile spawned")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if is_in_group("paused"):
		active = false
		sprite.texture = deactive_sprite
		area.set_collision_mask_value(1, false)
	else:
		active = true
		sprite.texture = default_sprite
		area.set_collision_mask_value(1, true)
	
	if active:
		if timer >= TRAVEL_TIME:
			#queue_free()
			print("projectile killed")
		else:
			timer += delta
			position.x += MOVE_DIR * SPEED

func _on_area_2d_body_entered(body):
	if active and body.name == "Player":
		body.die()
