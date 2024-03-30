extends CharacterBody2D

@export var move_speed := 250
@export var gravity := 2000
@export var jump_speed := 550
@export var max_jump_count := 2   # 0 -> player can't jump. 1  --> only 1 jump, 2 -> double jumps...


var is_jumping = false
var jump_count = 0
var changed_scale = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play()


func _physics_process(delta: float) -> void:
	# we check/apply the physics here!
	
	# reset horizontal velocity and disable sword hitbox by default
	velocity.x = 0
	
	# if we are on the floor - we reset the jump count to 0
	if is_on_floor():
		jump_count = 0

	# check user input and adjust horizontal velocity
	#var moving = false
	if Input.is_action_pressed("move_right"):
		velocity.x += move_speed
		#moving = true
	if Input.is_action_pressed("move_left"):
		velocity.x -= move_speed
		#moving = true
	
	# are we jumping ? or jumping again ?
	if Input.is_action_just_pressed("jump") and (jump_count < max_jump_count):
		jump_count += 1
		velocity.y = -jump_speed # negative Y is up in Godot

	# really ugly way of handling scale 
	# issue is that change of scale applies onto the previous scaling (so -1 * -1 means flipping)
	if (velocity.x < 0) and (!changed_scale):
		scale.x *= -1.0
		changed_scale = true
	elif (velocity.x > 0) and (changed_scale):
		scale.x *= -1.0
		changed_scale = false

	# apply gravity - player always has downward velocity
	velocity.y += gravity * delta

	# actually move the player
	#velocity = move_and_slide(velocity, Vector2.UP)
	move_and_slide()


func _process(_delta):
	# we specify the animations here 
	var animation = "idle"
	
	if !is_on_floor():
		animation = "jumping"
	elif velocity.x != 0:
		animation = "running"
	else:
		animation = "idle"

	$AnimatedSprite2D.animation = animation
