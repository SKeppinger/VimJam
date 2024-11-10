extends Node2D

var background;
var collision;
var progress = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background = $Background;
	collision = $Background/Area2D;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	background.material.set_shader_parameter("pos",progress);
	collision.position.x = progress * background.texture.get_width();
	progress += delta / 100;
