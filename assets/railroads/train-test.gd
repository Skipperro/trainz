extends KinematicBody

export (float) var speed = 5.0
export (float) var rotation_speed = speed/4

var velocity = Vector3()
var rotation_dir = 0

export var straight = true
export var left = false
export var right = false

func _physics_process(delta):
	if straight:
		rotation_dir = 0
	if left:
		rotation_dir = 1
	if right:
		rotation_dir = -1
	rotation.y += rotation_dir * rotation_speed * delta
	velocity = Vector3(0,0, speed).rotated(Vector3(0,1,0), rotation.y)
	velocity = move_and_slide(velocity)
	if straight and not left and not right:
		if abs(rotation_degrees.y) > 350 or abs(rotation_degrees.y) < 10:
			rotation_degrees.y = 0
			translation.x = round(translation.x)
		if abs(rotation_degrees.y) > 170 and abs(rotation_degrees.y) < 190:
			rotation_degrees.y = 180
			translation.x = round(translation.x)
		if abs(rotation_degrees.y) > 80 and abs(rotation_degrees.y) < 100:
			rotation_degrees.y = 90
			translation.y = round(translation.y)
		if abs(rotation_degrees.y) > 260 and abs(rotation_degrees.y) < 280:
			rotation_degrees.y = 270
			translation.y = round(translation.y)
