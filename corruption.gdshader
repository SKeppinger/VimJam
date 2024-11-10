shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}
uniform int amount = 100;
uniform float pos = 0.00;

void fragment() {
	// Called for every pixel the material is visible on.
	float aspect_ratio = TEXTURE_PIXEL_SIZE.y/TEXTURE_PIXEL_SIZE.x;
	vec2 grid_uv = round(UV * float(amount)) / float(amount);
	grid_uv.x = round(UV.x * float(amount)*aspect_ratio) / float(amount)/aspect_ratio;
	
	if (grid_uv.x < pos)
		COLOR = vec4(0, 0, 0, 1);
	else if (grid_uv.x - pos < random(grid_uv) / 10.0)
		COLOR = vec4(0, 0, 0, 1);
	else
		COLOR = vec4(1, 1, 1, 1);
}	

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
