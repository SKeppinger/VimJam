extends AnimatableBody2D

@export var MOVE_DIR = 0
@export var SPEED = 1.0
@export var MOVE_DISTANCE = 200.0

var moved = 0.0
var active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if MOVE_DIR == 0:
		MOVE_DIR = randi_range(0, 1)
		if MOVE_DIR == 0:
			MOVE_DIR = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if is_in_group("paused"):
		active = false
	else:
		active = true
	
	if active:
		if moved >= MOVE_DISTANCE:
			MOVE_DIR *= -1
			scale.x *= -1
			moved = 0.0
		
		position.x += MOVE_DIR * SPEED
		moved += SPEED
