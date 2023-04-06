extends CharacterBody3D

@export_range(0, 1) var sensitivity: float = 0.5;
@export_range(0, 90) var vertical_look_boundary: float = 80;
@export var invert_y_axis: bool = false;
@export var speed: float = 5.0
@export var jump_power: float = 4.5
@export var gravity: float = 10.0

@onready var camera: Camera3D = get_node("Camera3D");


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_power
	
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()


func _input(event):
	if (
			event is InputEventMouseMotion and
			Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	):
		rotate_y(-deg_to_rad(event.relative.x * sensitivity * 0.2))
		if invert_y_axis:
			camera.rotate_x(deg_to_rad(event.relative.y * sensitivity * 0.2))
		else:
			camera.rotate_x(-deg_to_rad(event.relative.y * sensitivity * 0.2))
		camera.rotation_degrees.x = clamp(
				camera.rotation_degrees.x,
				-vertical_look_boundary,
				vertical_look_boundary
		)
	if event.is_action("click"):
		if event.is_pressed() and not event.is_echo():
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
