extends Spatial

# How long is the train.
export(int) var wagons = 4
# Type of last wagon.
export(String, "Driver", "Coach") var last_wagon = "Driver" 
# Maximum speed.
export(float) var max_speed = 10.5
# How fast it accelerates.
export(float) var acceleration = 1.0
# How fast it slows down.
export(float) var brakes = 1.5
# Percentage of speed loss per second.
export(float) var air_drag = 0.0

var speed = 0.0

var wagon_nodes = []
var warmup_frames = 10

var wagon_template = preload("res://assets/railroads/Wagon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(wagons):
		add_wagon(i)
	print("OK")

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
	#new_wagon.path_queue.append('s')
	wagon_nodes.append(new_wagon)
	add_child(new_wagon)
	new_wagon.set_global_transform(global_transform)
	new_wagon.translation.z -= 4*index

	
func new_tile_spotted(straight, left, right):
	
	var wagon = wagon_nodes[0]
	#print("debug: " + wagon.name)
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
	

func direction_chosen(dir):
	#if dir:
	#	directions_log.append(dir)
	#	if directions_log.size() > 4:
	#		directions_log.pop_front()
	for i in range(wagon_nodes.size()):
		if i != 0:
			wagon_nodes[i].path_queue.append(dir)

var missed_delta = 0.0

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
		speed += acceleration*delta
		if speed > max_speed:
			speed = max_speed
	if Input.is_action_pressed("ui_down"):
		speed -= brakes*delta
	var speedloss = speed * air_drag * delta
	speed -= speedloss
	if speed < 0.0:
		speed = 0.0
	if speed > 0.0:
		for i in range(wagon_nodes.size()):
			wagon_nodes[i].move_forward(speed*delta)

