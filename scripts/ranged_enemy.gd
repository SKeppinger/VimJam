extends CharacterBody2D

var active = true
var animated_sprite
var projectile_scene = preload("res://scenes/projectile.tscn")

@export var FIRE_DIR = 1
@export var PROJECTILE_SPEED = 80.0
@export var FIRE_TIME = 0.3 # seconds
@export var PROJECTILE_TIME = 2.0 # seconds
@export var FIRE_RATE = 0.5 # projectiles per second

var fire_timer = 0.0
var hold_timer = 0.0

func _ready():
	animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	if is_in_group("paused"):
		active = false
	else:
		active = true

	if active:
		animated_sprite.play()
		if fire_timer < 1 / FIRE_RATE and hold_timer == 0.0:
			animated_sprite.frame = 0
			fire_timer += delta
		else:
			animated_sprite.frame = 1
			var projectile = projectile_scene.instantiate()
			projectile.set_values(FIRE_DIR, PROJECTILE_SPEED, PROJECTILE_TIME)
			projectile.position = position + Vector2(FIRE_DIR * 20, 0)
			fire_timer = 0.0
			hold_timer += delta
		if hold_timer > 0.0 and hold_timer < FIRE_TIME:
			hold_timer += delta
		elif hold_timer >= FIRE_TIME:
			hold_timer = 0.0
	else:
		animated_sprite.stop()

func _on_kill_area_body_entered(body):
	if body.name == "Player":
		body.die()
