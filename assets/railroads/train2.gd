extends Spatial

var path
var train
var follower
var pref_dir = "s"
var actual_dir = "s"
var power = 0.01
var asp


export var is_wagon = false
export var straight = false
export var left = true
export var right = false
var rotation_dir = 0

func _ready():
	path = $Path
	train = $KinematicBody
	follower = $Path/PathFollow
	plot_course("s")
	asp = $KinematicBody/AudioStreamPlayer
	if asp:
		asp.play()
		asp.pitch_scale = 0.1
	

func _process(delta):
	if $KinematicBody/cammount:
		$KinematicBody/cammount.rotation_degrees.y =  -135 - $KinematicBody.rotation_degrees.y

func _physics_process(delta):
	if Input.is_action_pressed("ui_up"):
		power += 0.2*delta
		if power > 1.0:
			power = 1.0
	if Input.is_action_pressed("ui_down"):
		power -= 0.3*delta
		if power < 0.00:
			power = 0.00
	else:
		if power < 0.0:
			power = 0.0
	
	if asp:
		asp.pitch_scale = 2*power + 0.01
		
	var speed = delta * 10 * power
	path = $Path
	train = $KinematicBody
	follower = $Path/PathFollow
	
	var distance = path.curve.get_baked_length()
	
	if follower.offset + speed >= distance:
		# Plot new course
		speed -= distance - follower.offset
		follower.offset = distance
		train.translation = follower.translation
		if straight:
			rotation_dir = 0
			actual_dir = "s"
		if left:
			rotation_dir = 1
			actual_dir = "l"
		if right:
			rotation_dir = -1
			actual_dir = "r"
		plot_course(actual_dir)
		
		follower.unit_offset = 0.0
		
	follower.offset += speed
	train.translation = follower.translation
	
	
	train.rotation_degrees.y += 90*speed*rotation_dir/(2*PI)
	
	
	if Input.is_action_just_released("lights"):
		if $KinematicBody/FrontLight:
			$KinematicBody/FrontLight.visible = not $KinematicBody/FrontLight.visible

func plot_course(direction):
	#path = $Path
	#follower = $Path/PathFollow
	#train = $KinematicBody
	
	var train_gps = train.transform.origin
	train.rotation_degrees.y = round(train.rotation_degrees.y)
	if train.rotation_degrees.y > 360.0:
		train.rotation_degrees.y -= 360.0
	if train.rotation_degrees.y < 0.0:
		train.rotation_degrees.y += 360.0
	
	if abs(train.rotation_degrees.y) > 330 or abs(train.rotation_degrees.y) < 30:
		train.rotation_degrees.y = 0
	if abs(train.rotation_degrees.y) > 150 and abs(train.rotation_degrees.y) < 210:
		train.rotation_degrees.y = 180
	if abs(train.rotation_degrees.y) > 60 and abs(train.rotation_degrees.y) < 120:
		train.rotation_degrees.y = 90
	if abs(train.rotation_degrees.y) > 240 and abs(train.rotation_degrees.y) < 300:
		train.rotation_degrees.y = 270
	
	var train_head = train.rotation_degrees
	#follower.rotation_degrees = train.rotation_degrees
	
	path.curve.clear_points()
	if direction == "s":
		path.curve.add_point(train_gps, Vector3(0,0,0), Vector3(0,0,0))
	else:
		path.curve.add_point(train_gps, Vector3(0,0,0), $KinematicBody/middle.global_transform.origin - train_gps)
	$Path/marker1.translation = train_gps
	$Path/marker3.translation = ($KinematicBody/middle.global_transform.origin)
	
	if direction == "l":
		path.curve.add_point($KinematicBody/left.global_transform.origin)
		$Path/marker2.translation = $KinematicBody/left.global_transform.origin		
	if direction == "s":
		path.curve.add_point($KinematicBody/straight.global_transform.origin)
		$Path/marker2.translation = $KinematicBody/straight.global_transform.origin
	if direction == "r":
		path.curve.add_point($KinematicBody/right.global_transform.origin)
		$Path/marker2.translation = $KinematicBody/right.global_transform.origin
	
	#print("Course plotted")
	


