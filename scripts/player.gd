extends CharacterBody2D

@export var SPEED = 300.0
@export var DASH_SPEED = 600.0
@export var DASH_TIME = 0.2 # seconds
@export var JUMP_VELOCITY = -400.0
@export var FAST_FALL_FACTOR = 3.0

var move_direction = 0

var has_air_dash = true
var dashing = false
var dash_direction = 1 # 1 for right, -1 for left
var dash_timer = 0.0

var has_double_jump = true

var fast_falling = false

# Handle dash functionality including:
# - Dash
# - Air Dash
func dash():
	# Dash
	if is_on_floor():
		dashing = true
		dash_direction = move_direction
	# Air Dash
	elif has_air_dash:
		dashing = true
		dash_direction = move_direction
		has_air_dash = false

# Handle jump functionality including:
# - Jump
# - Dash Jump
# - Double Jump
# - Wall Jump
func jump():
	# Jump/Dash Jump
	if is_on_floor():
		# If dashing or sliding, dash jump
		if dashing and dash_timer >= DASH_TIME / 2:
			dash_timer = 0.0
			velocity.y = JUMP_VELOCITY
		# Else, normal jump:
		else:
			velocity.y = JUMP_VELOCITY
	# Wall Jump
	elif is_on_wall():
		pass # Handle wall jump
	# Double Jump
	elif has_double_jump:
		fast_falling = false
		velocity.y = JUMP_VELOCITY
		has_double_jump = false

# Handle crouch functionality including:
# - Crouch
# - Slide
# - Fast Fall
func crouch():
	# Crouch/Slide
	if is_on_floor():
		# If dashing, slide
		# Else, crouch:
		pass
	# Fast Fall
	else:
		fast_falling = true

func _physics_process(delta):
	# GRAVITY AND COOLDOWNS
	# Add the gravity.
	if not is_on_floor():
		# If fast falling
		if fast_falling:
			velocity += get_gravity() * FAST_FALL_FACTOR * delta
		# Else, normal gravity
		else:
			velocity += get_gravity() * delta
	# Restore air options
	else:
		has_double_jump = true
		has_air_dash = true
		fast_falling = false

	# MOVEMENT OPTIONS
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		jump()
	# Handle dash:
	if Input.is_action_just_pressed("dash"):
		dash()
	# Handle crouch:
	if Input.is_action_just_pressed("crouch"):
		crouch()

	# MOVEMENT
	# If player is not dashing
	if !dashing:
		# Get the input direction and handle the movement/deceleration.
		move_direction = get_move_direction()
		if move_direction:
			velocity.x = move_direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	# If player is dashing
	else:
		velocity.x = dash_direction * DASH_SPEED
		dash_timer += delta
		if dash_timer > DASH_TIME:
			dashing = false
			dash_timer = 0.0
	move_and_slide()

# Unfortunately ugly movement direction logic
func get_move_direction():
	var dir = move_direction
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left"):
		if Input.is_action_just_pressed("move_right"):
			dir = 1
		if Input.is_action_just_pressed("move_left"):
			dir = -1
	if dir == -1 and not Input.is_action_pressed("move_left"):
		if Input.is_action_pressed("move_right"):
			dir = 1
	if dir == 1 and not Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			dir = -1
	if not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		dir = 0
	return dir
