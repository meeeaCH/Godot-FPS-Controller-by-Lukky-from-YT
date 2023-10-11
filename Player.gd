extends CharacterBody3D

#Player Nodes
#Head
@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var eyes = $Neck/Head/Eyes
@onready var camera_3d = $Neck/Head/Eyes/Camera3D
@onready var head_clear = $HeadClear

#Collision
@onready var standing_collision = $Standing_Collision
@onready var crouching_collision = $Crouching_Collision


# States
var is_crouching : bool = false
var is_free_looking : bool = false
var is_walking : bool = false
var is_sprinting : bool = false
var is_sliding : bool = false

# Slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_height = -1.1
var slide_speed = 6.0

# Head bobbing vars
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.1
const head_bobbing_walking_intensity = 0.05
const head_bobbing_crouching_intensity = 0.03

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Vars
var current_speed
const walking_speed = 5.0
const sprint_speed = 8.5
const jump_velocity = 4.5
const crouching_speed = 2.5
var crouching_height = -0.7 #relativ to the neck
var standing_height = 0.0  #relativ to the neck
const mouse_sens = 0.4

var lerp_speed = 10.0
var direction = Vector3.ZERO
var free_look_tilt_amount = -3
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#Handling camera look
	if event is InputEventMouseMotion:
		if is_free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:	
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens)) 
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	# Getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	#Movement states handling
	#Crouching  && !is_sliding
	if Input.is_action_pressed("crouch") || is_sliding and is_on_floor():
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, crouching_height, lerp_speed * delta)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
		# Slide beggin loggic
		if is_sprinting and input_dir != Vector2.ZERO:
			is_sliding = true		
			slide_timer = slide_timer_max
			slide_vector = input_dir
			is_free_looking = true
			print("Sliding beggin")
			
		is_crouching = true
		is_walking = false
		is_sprinting = false
	elif !head_clear.is_colliding():
		current_speed = walking_speed
		head.position.y = lerp(head.position.y, standing_height, lerp_speed * delta)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		is_crouching = false
		is_walking = true
		is_sprinting = false
		
	# Handle sliding
	if is_sliding:
		slide_timer -= delta
#		print("Sliding")
		if slide_timer <= 0:
			is_sliding = false
			is_free_looking = false
			print("Slide end")	
	
	# Handle Sprint
	if Input.is_action_pressed("sprint") and not is_crouching and not head_clear.is_colliding():
		current_speed = sprint_speed
		is_crouching = false
		is_walking = false
		is_sprinting = true
	else:
		is_crouching = false
		is_walking = true
		is_sprinting = false
		
	# Handle free looking  
	if Input.is_action_pressed("free_look") || is_sliding:
		is_free_looking = true
		if is_sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(7.0), lerp_speed * delta)
		else:
			camera_3d.rotation.z = deg_to_rad(neck.rotation.y * free_look_tilt_amount)	
	else:
		is_free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, lerp_speed * delta)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, lerp_speed * delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Handle Jump.
	if is_on_floor() && not is_sliding && not is_crouching && Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), lerp_speed * delta)
	
	# Head bobbing
	if is_sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif is_walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif is_crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	if is_on_floor() and !is_sliding and input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)	
		head_bobbing_vector.x = sin(head_bobbing_index / 2) +0.5	
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y *(head_bobbing_current_intensity / 2.0), lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, lerp_speed * delta)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, 0.0, lerp_speed * delta)
		
	
	# 
	if is_sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if is_sliding:
			velocity.x = direction.x * (slide_timer + 1.0) * slide_speed
			velocity.z = direction.z * (slide_timer + 1.0) * slide_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
