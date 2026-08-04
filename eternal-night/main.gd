extends Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var moon_light: DirectionalLight3D = $DirectionalLight3D
@onready var chunk_manager: Node3D = $ChunkManager
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	_setup_environment()
	_setup_moon()
	_setup_player_spawn()


func _setup_player_spawn() -> void:
	var spawn_x := player.global_position.x
	var spawn_z := player.global_position.z
	var terrain_height: float = chunk_manager.get_terrain_height(spawn_x, spawn_z)
	player.global_position.y = terrain_height + 1.0


func _setup_environment() -> void:
	var env := Environment.new()

	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://shaders/star_sky.gdshader")
	sky_material.set_shader_parameter("sky_top_color", Color(0.015, 0.025, 0.055))
	sky_material.set_shader_parameter("sky_horizon_color", Color(0.04, 0.06, 0.12))
	sky_material.set_shader_parameter("ground_horizon_color", Color(0.02, 0.025, 0.04))
	sky_material.set_shader_parameter("ground_bottom_color", Color(0.01, 0.012, 0.02))
	sky_material.set_shader_parameter("star_density", 0.18)
	sky_material.set_shader_parameter("twinkle_speed", 1.8)
	sky_material.set_shader_parameter("star_brightness", 1.2)
	sky.sky_material = sky_material

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.25, 0.28, 0.35)
	env.ambient_light_energy = 0.55

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.015, 0.025, 0.045)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.0

	world_environment.environment = env


func _setup_moon() -> void:
	moon_light.light_color = Color(0.75, 0.85, 1.0)
	moon_light.light_energy = 0.65
	moon_light.light_indirect_energy = 0.5
	moon_light.shadow_enabled = true
	moon_light.shadow_bias = 0.05
	moon_light.rotation_degrees = Vector3(-55, -35, 0)
