extends CharacterBody2D

@export var MOVE_DIR = 0
@export var SPEED = 80.0
@export var MOVE_DISTANCE = 16000.0

var active = true
var animated_sprite
var moved = 0.0

func _ready():
	animated_sprite = $AnimatedSprite2D
	if MOVE_DIR == 0:
		MOVE_DIR = randi_range(0, 1)
		if MOVE_DIR == 0:
			MOVE_DIR = -1
	scale.x *= MOVE_DIR

func _physics_process(_delta):
	
	if is_in_group("paused"):
		active = false
	else:
		active = true
	
	if active:
		animated_sprite.play()
		if moved >= MOVE_DISTANCE:
			MOVE_DIR *= -1
			scale.x *= -1
			moved = 0.0
		
		velocity.x = MOVE_DIR * SPEED
		moved += SPEED
		move_and_slide()
	else:
		animated_sprite.stop()

func _on_kill_area_body_entered(body):
	if body.name == "Player":
		body.die()
