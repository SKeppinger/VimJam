extends Node2D

var background;
var collision;
var player;
var progress = 0;
var speed = 0.1;
var collision_offset = 150;
var visibility;
var death_screen;
var completed = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background = $Background;
	collision = $Background/DeathBarrier;
	player = $"../Player";
	visibility = $Background/DeathBarrier/VisibleOnScreenNotifier2D;
	death_screen = $CanvasLayer/DeathScreen/AnimationPlayer;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (player && !completed && 
		collision.position.x > player.position.x && 
		!visibility.is_on_screen()
	):
		death_screen.play("fade_to_black");
		completed = true;
	elif (!completed):
		background.material.set_shader_parameter("pos",progress);
		collision.position.x = position.x + (progress * background.texture.get_width() + collision_offset);
		progress += delta * speed / 100;
	print("vis:" + str(visibility.global_position.x))
	print("player:" + str(player.position.x))

func _on_player_death():
	speed = 10;
	if !visibility.is_on_screen():
		position.x = player.position.x - player.get_node("Camera2D").get_viewport_rect().size.x
		print(collision.position.x)
	
