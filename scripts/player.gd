extends CharacterBody2D

# Exported Properties
@export var SPEED = 300.0
@export var DASH_SPEED = 600.0
@export var CROUCH_SPEED = 100.0
@export var DASH_TIME = 0.3 # seconds
@export var DASH_JUMP_WINDOW = 0.2 # seconds after the dash has started
@export var SLIDE_WINDOW = 0.1 # seconds after the dash has started
@export var SLIDE_TIME = 0.15 # seconds
@export var SLIDE_FALLOFF = 20.0 # the lower this number, the more speed kept from sliding
@export var JUMP_VELOCITY = -400.0
@export var FAST_FALL_FACTOR = 3.0

# Children Nodes
var standing_hitbox
var crouching_hitbox
var sprite

# Control Variables
var move_direction = 0
var last_move_direction = 0 # Used for more forgiving dashes

var has_air_dash = true
var dashing = false
var air_dashing = false
var dash_direction = 1 # 1 for right, -1 for left
var dash_timer = 0.0

var has_double_jump = true

var fast_falling = false
var crouching = false
var sliding = false

# Sprites
var crouch_sprite = load("res://assets/temp_crouch.png")
var stand_sprite = load("res://assets/temp_player.png")

# Initialize child node references
func _ready():
	standing_hitbox = $StandingCollisionBox
	crouching_hitbox = $CrouchingCollisionBox
	sprite = $Sprite2D

# Handle dash functionality including:
# - Dash
# - Air Dash
func dash():
	# Dash
	if is_on_floor():
		dashing = true
		if move_direction == 0:
			dash_direction = last_move_direction
		else:
			dash_direction = move_direction
	# Air Dash
	elif has_air_dash:
		velocity.y = 0
		dashing = true
		air_dashing = true
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
		if dashing and dash_timer >= DASH_JUMP_WINDOW: # Timing window to initiate a Dash Jump
			dash_timer = 0.0 # Dash Jump extends the dash to be longer, translating to horizontal speed in the air
			velocity.y = JUMP_VELOCITY
		# Else, normal jump:
		else:
			velocity.y = JUMP_VELOCITY
	# Wall Jump
	elif is_on_wall():
		pass # Handle wall jump
	# Double Jump
	elif has_double_jump:
		fast_falling = false # Double Jump should reset fast fall
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
		if dashing:
			sliding = true
			crouching = true
			if dash_timer >= SLIDE_WINDOW: # If the Slide is initiated near the end of the dash,
				dash_timer -= SLIDE_TIME # extend the dash time by a bit
		# Else, crouch:
		else:
			crouching = true
	# Fast Fall
	else:
		air_dashing = false
		dashing = false
		dash_timer = 0.0 # Fast Fall cancels air dash
		fast_falling = true

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
	if dir != 0:
		last_move_direction = dir
	return dir

func _physics_process(delta):
	# GRAVITY AND COOLDOWNS
	# Add the gravity.
	if not is_on_floor() and not air_dashing:
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
	
	# CROUCH CHECK
	# If crouching and not holding the crouch button, stop crouching/sliding
	if crouching and not Input.is_action_pressed("crouch"):
		crouching = false
		if not dashing:
			sliding = false
	
	# SPRITES AND HITBOXES
	# If crouching, sliding, or fast falling, use the crouching sprite/hitbox
	if crouching or sliding or fast_falling:
		sprite.texture = crouch_sprite
	# Otherwise, use the standing sprite/hitbox
	else:
		sprite.texture = stand_sprite
	
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
	# If player is not dashing and not crouching
	if !dashing and !crouching:
		# Get the input direction and handle the movement/deceleration.
		move_direction = get_move_direction()
		if move_direction:
			velocity.x = move_direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	# If player is dashing
	elif dashing:
		velocity.x = dash_direction * DASH_SPEED
		dash_timer += delta
		if dash_timer > DASH_TIME:
			dashing = false
			air_dashing =  false
			dash_timer = 0.0
	# If player is sliding
	elif crouching:
		# Get the input direction and handle the movement/deceleration.
		move_direction = get_move_direction()
		# If player is sliding, slow down
		if sliding:
			velocity.x = move_toward(velocity.x, CROUCH_SPEED * move_direction, SLIDE_FALLOFF)
			if velocity.x == CROUCH_SPEED * move_direction:
				sliding = false
		# Otherwise, use crouched move speed
		else:
			if move_direction:
				velocity.x = move_direction * CROUCH_SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, CROUCH_SPEED)
	move_and_slide()
