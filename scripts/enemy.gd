extends CharacterBody2D

var active = true
var animated_sprite

@export var MOVE_DIR = 0
@export var SPEED = 80.0

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
		var space = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(position, position + Vector2(MOVE_DIR * 50, 100))
		query.set_collision_mask(0b1000)
		var ray_cast = space.intersect_ray(query)
		
		if is_on_wall() or ray_cast.is_empty():
			MOVE_DIR *= -1
			scale.x *= -1
		
		velocity += get_gravity()
		velocity.x = MOVE_DIR * SPEED
		move_and_slide()
	else:
		animated_sprite.stop()

func _on_kill_area_body_entered(body):
	if body.name == "Player":
		body.die()
