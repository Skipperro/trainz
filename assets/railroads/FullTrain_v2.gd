extends Spatial

# How long is the train.
export(int, 1, 8) var wagons = 4
# Type of last wagon.
export(String, "Driver", "Coach") var last_wagon = "Driver" 
# Maximum speed.
export(float, 0.0, 20.0) var max_speed = 10.1
# How fast it accelerates.
export(float, 0.0, 0.5) var acceleration = 0.1
# How fast it slows down.
export(float, 0.0, 0.5) var brakes = 0.1

# Current percentage of power (from 0 to 1)
var throttle = 0.01
# Current speed derived from throttle
var speed = 0.01
# List of wagons that make the train (added with add_wagon function
var wagon_nodes = []
# Skip calculations for X first frames to avoid kraken attack.
var warmup_frames = 2
# Preloaded wagon scene to use in add_wagon function. 
var wagon_template = preload("res://assets/railroads/Wagon.tscn")
# Amount of time lost due to low FPS.
var missed_delta = 0.0
# Node for EngineSound
var n_engine
# Node for mounting the camera
var cammount
# Node for the camera
var camera
# Node for fist KinematicBody
var trainhead
# Throttle GUI element
var throttle_gui
# Speed GUI element
var speed_bar
# Speed progressbar colors
var pb_colors = [preload("res://assets/railroads/progressbar_white.tres"), preload("res://assets/railroads/progressbar_red.tres")]


# Called when the node enters the scene tree for the first time.
func _ready():
	n_engine = $EngineSound
	cammount = $cammount
	camera = $cammount/cammount/Camera
	throttle_gui = $Control/VSlider
	speed_bar = $Control/ProgressBar
	for i in range(wagons):
		add_wagon(i)
	trainhead = wagon_nodes[0].get_node("KinematicBody").get_node("campoint")
	print("OK")

# Called on creation of the train to setup the wagons.
func add_wagon(index):
	var new_wagon = wagon_template.instance()
	new_wagon.name = "wagon" + str(index)
	if index > 0:
		new_wagon.set_type("Coach")
		if index == wagons-1 and last_wagon == "Driver":
			new_wagon.set_type("Driver")
			new_wagon.invert_wagon()
	else:
		new_wagon.set_head(true)
		new_wagon.set_type("Driver")
		new_wagon.connect("spot_new_tile", self, "new_tile_spotted")
		new_wagon.connect("direction_chosen", self, "direction_chosen")
	for i in range(index):
		new_wagon.path_queue.append('s')
	wagon_nodes.append(new_wagon)
	add_child(new_wagon)
	new_wagon.set_global_transform(global_transform)
	new_wagon.translation.z -= 4*index

# Called by signal from the first wagon when arriving at new important point on map.
func new_tile_spotted(straight, left, right):
	var wagon = wagon_nodes[0]
	wagon.path_queue.clear()
	
	if Input.is_action_pressed("ui_left") and left:
		wagon.path_queue.append('l')
		return
	if Input.is_action_pressed("ui_right") and right:
		wagon.path_queue.append('r')
		return
	
	if straight:
		wagon.path_queue.append('s')
		return
	if right:
		wagon.path_queue.append('r')
		return
	if left:
		wagon.path_queue.append('l')
		return

# Called by signal from the first wagon when new direction is taken.
func direction_chosen(dir):
	for i in range(wagon_nodes.size()):
		if i != 0:
			wagon_nodes[i].path_queue.append(dir)

# Called 60 times per second to drive the train.
func _physics_process(delta):
	if warmup_frames > 0:
		warmup_frames -= 1
		return
	delta += missed_delta
	if delta > 0.03:
		print("Low FPS detected!")
		missed_delta = delta - 0.03
		delta = 0.03
	if Input.is_action_pressed("ui_up"):
		throttle_gui.value += 0.5*delta
		if throttle_gui.value > 1.0:
			throttle_gui.value = 1.0
	if Input.is_action_pressed("ui_down"):
		throttle_gui.value -= 0.5*delta
	if throttle_gui.value < 0.0:
		throttle_gui.value = 0.0
	throttle = throttle_gui.value	
	
	if throttle > speed + 0.33:
		throttle = 0.0
		speed_bar.set("custom_styles/fg", pb_colors[1])
	else:
		speed_bar.set("custom_styles/fg", pb_colors[0])
	
	if throttle > speed:
		speed += (throttle-speed) * acceleration*2 * delta
		if speed > throttle:
			speed = throttle
	else:
		speed -= brakes * delta
		if throttle < speed - 0.33:
			speed -= brakes * delta
			speed_bar.set("custom_styles/fg", pb_colors[1])
		if speed < throttle:
			speed = throttle	
	
	speed_bar.value = speed
	if speed > 0.0:
		if not n_engine.playing:
			n_engine.playing = true
		n_engine.pitch_scale = speed*2
		for i in range(wagon_nodes.size()):
			wagon_nodes[i].move_forward(speed*max_speed*delta)
	else:
		n_engine.pitch_scale = 0.001
	trainhead.translation.z = 8*speed
	var camtarget = trainhead.global_transform.origin
	var cammove_vector = camtarget - cammount.global_transform.origin
	cammount.global_translate(cammove_vector*delta*2)

