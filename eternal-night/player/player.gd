extends CharacterBody3D

@export var speed := 6.0
@export var acceleration := 10.0
@export var friction := 12.0
@export var rotation_speed := 12.0
@export var camera_auto_align_speed := 2.0
@export var mouse_sensitivity := 0.004
@export var auto_align_delay := 1.2
@export var jump_velocity := 6.0
@export var gravity_multiplier := 1.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var mesh: Node3D = $Model
@onready var animation_player: AnimationPlayer = mesh.find_child("AnimationPlayer", true, false) as AnimationPlayer

var _mouse_input := Vector2.ZERO
var _last_mouse_time := 0

const GRAVITY := 9.8


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.rotation.x = -0.35

	if animation_player != null:
		animation_player.set_blend_time("idle", "walk", 0.2)
		animation_player.set_blend_time("walk", "idle", 0.2)
		animation_player.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_input = event.relative
		_last_mouse_time = Time.get_ticks_msec()
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	if _mouse_input != Vector2.ZERO:
		spring_arm.rotation.y -= _mouse_input.x * mouse_sensitivity
		spring_arm.rotation.x -= _mouse_input.y * mouse_sensitivity
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, -PI / 2.2, -0.05)
		_mouse_input = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * gravity_multiplier * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)

	if input_dir != Vector2.ZERO:
		var cam_basis := spring_arm.global_transform.basis
		var direction := (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y).normalized()
		direction.y = 0.0
		direction = direction.normalized()

		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)

		var target_rotation := atan2(direction.x, direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_rotation, rotation_speed * delta)

		var now := Time.get_ticks_msec()
		if (now - _last_mouse_time) > int(auto_align_delay * 1000.0):
			var target_yaw := mesh.rotation.y + PI
			spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, target_yaw, camera_auto_align_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	_update_animation(input_dir)
	move_and_slide()


func _update_animation(input_dir: Vector2) -> void:
	if animation_player == null:
		return

	if is_on_floor():
		if input_dir != Vector2.ZERO:
			if animation_player.current_animation != "walk":
				animation_player.play("walk")
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
	else:
		# 模型没有 jump 动画，空中保持 idle
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
