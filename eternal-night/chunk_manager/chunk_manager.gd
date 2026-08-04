extends Node3D

@export var chunk_size := 32.0
@export var load_radius := 5
@export var update_interval := 0.1
@export var segments := 32
@export var height_scale := 60.0
@export var noise_frequency := 0.003
@export var noise_seed := 42

var _chunks := {}
var _ground_material: StandardMaterial3D
var _height_noise: FastNoiseLite
var _timer := 0.0

@onready var _player: Node3D


func _ready() -> void:
	_ground_material = StandardMaterial3D.new()
	_ground_material.albedo_color = Color(0.14, 0.14, 0.16)
	_ground_material.roughness = 0.92

	_height_noise = FastNoiseLite.new()
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_height_noise.frequency = noise_frequency
	_height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height_noise.fractal_octaves = 2
	_height_noise.fractal_lacunarity = 2.0
	_height_noise.fractal_gain = 0.5
	_height_noise.seed = noise_seed

	var player_node := get_node_or_null("../Player")
	if player_node != null:
		_player = player_node
		_update_chunks()


func _process(delta: float) -> void:
	if _player == null:
		return

	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_update_chunks()


func _update_chunks() -> void:
	var px := floori(_player.global_position.x / chunk_size)
	var pz := floori(_player.global_position.z / chunk_size)
	var player_chunk := Vector2i(px, pz)

	var to_keep := {}
	for x in range(player_chunk.x - load_radius, player_chunk.x + load_radius + 1):
		for z in range(player_chunk.y - load_radius, player_chunk.y + load_radius + 1):
			var coord := Vector2i(x, z)
			to_keep[coord] = true
			if not _chunks.has(coord):
				_spawn_chunk(coord)

	var to_remove: Array[Vector2i] = []
	for coord in _chunks.keys():
		if not to_keep.has(coord):
			to_remove.append(coord)

	for coord in to_remove:
		var chunk: Node = _chunks[coord]
		chunk.queue_free()
		_chunks.erase(coord)


func get_terrain_height(world_x: float, world_z: float) -> float:
	var raw_noise := _height_noise.get_noise_2d(world_x, world_z)
	return (raw_noise + 1.0) * 0.5 * height_scale


func _spawn_chunk(coord: Vector2i) -> void:
	var chunk := StaticBody3D.new()
	chunk.position = Vector3(coord.x * chunk_size, 0.0, coord.y * chunk_size)
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]

	var terrain_mesh := _create_terrain_mesh(coord)
	terrain_mesh.surface_set_material(0, _ground_material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = terrain_mesh
	chunk.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var concave_shape := ConcavePolygonShape3D.new()
	concave_shape.set_faces(terrain_mesh.get_faces())
	collision.shape = concave_shape
	chunk.add_child(collision)

	add_child(chunk)
	_chunks[coord] = chunk


func _create_terrain_mesh(coord: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_size := chunk_size * 0.5
	var world_base_x := coord.x * chunk_size
	var world_base_z := coord.y * chunk_size

	for z in range(segments + 1):
		for x in range(segments + 1):
			var local_x := -half_size + x * chunk_size / segments
			var local_z := -half_size + z * chunk_size / segments
			var world_x := world_base_x + local_x
			var world_z := world_base_z + local_z
			var raw_noise := _height_noise.get_noise_2d(world_x, world_z)
			var height := (raw_noise + 1.0) * 0.5 * height_scale

			st.set_uv(Vector2(x / float(segments), z / float(segments)))
			st.add_vertex(Vector3(local_x, height, local_z))

	for z in range(segments):
		for x in range(segments):
			var i := z * (segments + 1) + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + segments + 1)
			st.add_index(i + 1)
			st.add_index(i + segments + 2)
			st.add_index(i + segments + 1)

	st.generate_normals()
	return st.commit()
