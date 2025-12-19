extends CharacterBody3D

# Movement parameters
@export var walk_speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003

# Camera parameters
@export var third_person_distance = 3.0
@export var first_person_distance = 0.0
@export var camera_transition_speed = 10.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera references
@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D
@onready var camera = $CameraPivot/SpringArm3D/Camera3D

# Camera state
var is_first_person = false
var target_camera_distance = third_person_distance

func _ready():
	# Capture the mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Exclude the player from SpringArm collision detection
	spring_arm.add_excluded_object(get_rid())

func _input(event):
	# Camera rotation with mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Rotate camera pivot vertically
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)

		# Clamp vertical rotation to prevent flipping
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2, PI/2)

	# Toggle camera view
	if event.is_action_pressed("toggle_camera"):
		toggle_camera_view()

	# Release mouse with ESC (useful for testing)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction (relative to player's rotation)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Calculate movement direction relative to where player is facing
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Determine speed (could add sprint later)
	var speed = walk_speed

	# Apply movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Smooth stop
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Smooth camera transition between first/third person
	var current_length = spring_arm.spring_length
	spring_arm.spring_length = lerp(current_length, target_camera_distance, camera_transition_speed * delta)

	move_and_slide()

func toggle_camera_view():
	is_first_person = !is_first_person

	if is_first_person:
		target_camera_distance = first_person_distance
	else:
		target_camera_distance = third_person_distance
