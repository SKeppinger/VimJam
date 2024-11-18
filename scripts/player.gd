extends CharacterBody2D

# Exported Properties
@export var PAUSE_TIME = 1.0 # seconds
@export var FRICTION = 30.0
@export var AIR_RESIST = 1.0
@export var ACCELERATION = 60.0
@export var AIR_ACCEL = 20.0
@export var SPEED = 300.0
@export var DASH_SPEED = 600.0
@export var CROUCH_SPEED = 100.0
@export var SLOPE_SLIDE_SPEED = 400.0
@export var DASH_TIME = 0.3 # seconds
@export var DASH_JUMP_WINDOW = 0.2 # seconds after the dash has started
@export var SLIDE_WINDOW = 0.1 # seconds after the dash has started
@export var SLIDE_TIME = 0.15 # seconds
@export var SLIDE_FALLOFF = 5.0 # the lower this number, the more speed kept from sliding
@export var JUMP_VELOCITY = -400.0
@export var COYOTE_TIME = 0.1
@export var FAST_FALL_FACTOR = 3.0
@export var WALL_JUMP_VELOCITY_Y = -300
@export var WALL_JUMP_VELOCITY_X = 500
@export var WALL_JUMP_TIME = 0.1 # seconds

static var START_POSITION = Vector2(578,504)

signal death

# Children/Sibling Nodes
var standing_hitbox
var crouching_hitbox
#var sprite
var animated_sprite
var pause_label
var music
var sfx

# Control Variables
var dead = false

var paused = false
var pause_timer = 0.0

var move_direction = 0
var last_move_direction = 0 # Used for more forgiving dashes

var coyote_timer = 0.0

var has_air_dash = true
var dashing = false
var air_dashing = false
var dash_direction = 1 # 1 for right, -1 for left
var dash_timer = 0.0

var has_double_jump = true

var wall_jumping = false
var wall_jump_timer = 0.0

var fast_falling = false
var crouching = false
var sliding = false

# Sprites
var crouch_sprite = load("res://assets/temp_crouch.png")
var stand_sprite = load("res://assets/temp_player.png")
# SFX
var jump_sound = load("res://assets/sounds/Jump.wav")
var dash_sound = load("res://assets/sounds/Notso_Confirm.wav")
var pause_sound = load("res://assets/sounds/Pause.wav")
var death_sound = load("res://assets/sounds/Explosion.wav")
var corruption_sound = load("res://assets/sounds/Evil_Laugh.wav")

# Play a sound
func play_sound(sound):
	sfx.stream = sound
	sfx.play()

# Initialize child node references
func _ready():
	standing_hitbox = $StandingCollisionBox
	crouching_hitbox = $CrouchingCollisionBox
	#sprite = $Sprite2D
	animated_sprite = $AnimatedSprite2D
	pause_label = $"../Corruption/CanvasLayer/Label" # actual level
	#pause_label = $"../Label" # test level
	position = START_POSITION
	music = $Music
	sfx = $SFX

# Handle pause functionality
func pause():
	if not paused:
		for node in get_tree().get_nodes_in_group("pausable"):
			node.add_to_group("paused")
		paused = true

# Handle dash functionality including:
# - Dash
# - Air Dash
func dash():
	# Dash
	if is_on_floor():
		play_sound(dash_sound)
		dashing = true
		animated_sprite.play("dash")
		if move_direction == 0:
			dash_direction = last_move_direction
		else:
			dash_direction = move_direction
	# Air Dash
	elif has_air_dash:
		#Otherwise you can airdash in place in the air
		if move_direction == 0:
			pass
		else:
			play_sound(dash_sound)
			velocity.y = 0
			dashing = true
			air_dashing = true
			animated_sprite.play("air_dash")
			dash_direction = move_direction
			has_air_dash = false

# Handle jump functionality including:
# - Jump
# - Dash Jump
# - Double Jump
# - Wall Jump
func jump():
	# Jump/Dash Jump
	if is_on_floor() or coyote_timer < COYOTE_TIME:
		# If dashing or sliding, dash jump
		if dashing and dash_timer >= DASH_JUMP_WINDOW: # Timing window to initiate a Dash Jump
			print("dash jump!") #For my own sanity atm
			dash_timer = 0.0 # Dash Jump extends the dash to be longer, translating to horizontal speed in the air
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")
			play_sound(jump_sound)
			animated_sprite.frame = 0
		# Else, normal jump:
		else:
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")
			play_sound(jump_sound)
			animated_sprite.frame = 0
	# Wall Jump
	elif is_on_wall_only():
		print("wall jump")
		play_sound(jump_sound)
		has_air_dash = true
		wall_jumping = true
		fast_falling = false # Wall jump should reset fast fall
		velocity.y = WALL_JUMP_VELOCITY_Y
		velocity.x = WALL_JUMP_VELOCITY_X * get_wall_normal().x
	# Double Jump
	elif has_double_jump and not is_on_floor():
		print("double jump")
		play_sound(jump_sound)
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
			animated_sprite.play("slide")
			if dash_timer >= SLIDE_WINDOW: # If the Slide is initiated near the end of the dash,
				dash_timer -= SLIDE_TIME # extend the dash time by a bit
		#If you crouch on a slope, slide
		if is_on_floor() and get_floor_angle()!= 0:
			sliding = true
			crouching = true
			animated_sprite.play("slide")
		# Else, crouch:
		else:
			crouching = true
			animated_sprite.play("slide")
			
	# Fast Fall
	else:
		air_dashing = false
		dashing = false
		dash_timer = 0.0 # Fast Fall cancels air dash
		fast_falling = true
		crouching = true
		animated_sprite.play("slide")

# Unfortunately ugly movement direction logic
func get_move_direction():
	if paused:
		return 0
	var dir = move_direction
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left"):
		if Input.is_action_just_pressed("move_right"):
			dir = 1
		if Input.is_action_just_pressed("move_left"):
			dir = -1
	if dir != 1 and not Input.is_action_pressed("move_left"):
		if Input.is_action_pressed("move_right"):
			dir = 1
	if dir != -1 and not Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			dir = -1
	if not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		dir = 0
	if dir != 0:
		last_move_direction = dir
	return dir

func _physics_process(delta):
	#print(is_on_floor())
	#print(is_on_wall())
	if not dead:
		#ANIMATIONS
		# Face the movement direction
		if sign(velocity.x) == 1 and sign(animated_sprite.scale.x) == -1:
			animated_sprite.scale.x *= -1
		elif sign(velocity.x) == -1 and sign(animated_sprite.scale.x) == 1:
			animated_sprite.scale.x *= -1
		if air_dashing:
			animated_sprite.scale.x *= -1
		# Manage jump frames
		if animated_sprite.animation == "jump":
			if velocity.y < 0 and animated_sprite.frame != 0 and animated_sprite.frame != 1:
				animated_sprite.frame = 2
			elif not is_on_floor():
				animated_sprite.frame = 2
			elif animated_sprite.frame != 3:
				animated_sprite.frame = 3
		# Manage dash animation
		if animated_sprite.animation == "dash" and not dashing:
			animated_sprite.stop()
		# Manage crouch and fast fall animation
		if animated_sprite.animation == "slide" and not sliding:
			if not is_on_floor() or (is_on_floor() and velocity.x == 0):
				animated_sprite.frame = 0
		# Default animations
		if not is_on_floor() and not dashing and not fast_falling and not sliding and not crouching:
			animated_sprite.play("jump")
		elif is_on_floor() and not dashing and not crouching and velocity.x == 0:
			animated_sprite.play("idle")
		elif is_on_floor() and not dashing and not crouching:
			animated_sprite.play("run")
		
		# PAUSE TIMER
		if paused:
			music.volume_db = -25
			pause_timer += delta
			pause_label.text = "%.2f" % pause_timer
			if pause_timer >= PAUSE_TIME:
				paused = false
				music.volume_db = -12
				pause_timer = 0.0
				for node in get_tree().get_nodes_in_group("paused"):
					node.remove_from_group("paused")
				pause_label.text = ""
		
		# GRAVITY AND COOLDOWNS
		if not is_on_floor() and not air_dashing:
			# Increment coyote timer
			coyote_timer += delta
			# If fast falling
			if fast_falling:
				velocity += get_gravity() * FAST_FALL_FACTOR * delta
			# Else, normal gravity
			elif coyote_timer > COYOTE_TIME:
				velocity += get_gravity() * delta
		# Restore air options
		elif is_on_floor():
			coyote_timer = 0.0
			has_double_jump = true
			has_air_dash = true
			fast_falling = false
		
		# CROUCH CHECK
		# If crouching and not holding the crouch button, stop crouching/sliding
		if (crouching or sliding) and not Input.is_action_pressed("crouch"):
			crouching = false
			if not dashing:
				sliding = false
		
		# SPRITES AND HITBOXES
		# If crouching, sliding, or fast falling, use the crouching sprite/hitbox
		if crouching or sliding or fast_falling:
			#sprite.texture = crouch_sprite
			standing_hitbox.disabled = true
			crouching_hitbox.disabled = false
		# Otherwise, use the standing sprite/hitbox
		else:
			#sprite.texture = stand_sprite
			standing_hitbox.disabled = false
			crouching_hitbox.disabled = true
		
		# INPUT
		# Handle jump.
		if Input.is_action_just_pressed("jump"):
			jump()
		# Handle dash:
		if Input.is_action_just_pressed("dash"):
			dash()
		# Handle crouch:
		if Input.is_action_just_pressed("crouch") or crouching:
			crouch()
		# Handle pause
		if Input.is_action_just_pressed("pause"):
			pause()

		# MOVEMENT
		if not paused:
			# If player is not dashing and not crouching and not wall jumping
			if !dashing and (!crouching or fast_falling) and !wall_jumping:
				# Get the input direction and handle the movement/deceleration.
				move_direction = get_move_direction()
				if move_direction:
					if is_on_floor():
						velocity.x += move_direction * ACCELERATION
					else:
						velocity.x += move_direction * AIR_ACCEL
					if abs(velocity.x) > SPEED * move_direction and sign(velocity.x) == sign(move_direction):
						velocity.x = SPEED * move_direction
				elif is_on_floor():
					velocity.x = move_toward(velocity.x, 0, FRICTION)
				else:
					velocity.x = move_toward(velocity.x, 0, AIR_RESIST)
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
				# If player is sliding on a dash, slow down
				if sliding:
					#temporary check if we want to be able to dash-slide on slope (I think)
					if get_floor_angle()==0:
						print("sliding!")
						velocity.x = move_toward(velocity.x, CROUCH_SPEED * move_direction, SLIDE_FALLOFF)
						if velocity.x == CROUCH_SPEED * move_direction:
							sliding = false
					#Sliding on a slope
					else:
						print("sliding on a slope!")
						print(get_floor_angle())
						#Right now it just affects x velocity, so it's very bumpy
						#I thought this would work? But floor angle keeps fluctuating between >1 <1 so it just makes the slide dumb
						if get_floor_angle()>1:
							velocity.x = move_toward(velocity.x, -1*SLOPE_SLIDE_SPEED, SLIDE_FALLOFF)
							if velocity.x == SLOPE_SLIDE_SPEED:
								sliding = false
						else:
							velocity.x = move_toward(velocity.x, SLOPE_SLIDE_SPEED, SLIDE_FALLOFF)
							if velocity.x == SLOPE_SLIDE_SPEED:
								sliding = false
					
				# Otherwise, use crouched move speed
				else:
					if move_direction:
						velocity.x = move_direction * CROUCH_SPEED
					else:
						velocity.x = move_toward(velocity.x, 0, CROUCH_SPEED)
			#If player is wall jumping
			elif wall_jumping:
				velocity.x = WALL_JUMP_VELOCITY_X * -1 * move_direction
				wall_jump_timer += delta
				if wall_jump_timer >= WALL_JUMP_TIME:
					wall_jumping = false
					wall_jump_timer = 0.0

		move_and_slide()
		
	else:
		music.volume_db -= delta * 10
		if music.volume_db < -100:
			music.stop()

func _on_death_barrier_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		die();

func _on_goal_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Player has reached the goal");
		
func die():
	if not dead:
		print("Player has died")
		death.emit()
		animated_sprite.play("death")
		dead = true
		play_sound(death_sound)
	
#Kill (with hammers)
func _on_visible_on_screen_notifier_2d_screen_exited():
	die()

#checkpoint!!!
func _on_checkpoint_body_entered(body):
	if body.name == "Player":
		START_POSITION = position
		
	
