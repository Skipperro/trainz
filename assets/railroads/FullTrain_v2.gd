extends Spatial

# How long is the train.
export(int, 1, 8) var wagons = 4
# Capacity per wagon
export(int, 10, 100) var wagon_capacity = 30
# Substracted capacity due to driver seats
export(int, 1, 50) var substracted_space = 20
# Type of last wagon.
export(String, "Driver", "Coach") var last_wagon = "Driver" 
# Maximum speed.
export(float, 0.0, 20.0) var max_speed = 10.1
# How fast it accelerates.
export(float, 0.0, 0.5) var acceleration = 0.1
# How fast it slows down.
export(float, 0.0, 0.5) var brakes = 0.1
# How many people for different stations are onboard.
var commuters_inside = [0,0,0,0,0,0]
# Collected money from tickets
var money = 0
# Is the door opened?
var opened = false

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
onready var n_engine = $cammount/EngineSound
# Node for mounting the camera
onready var cammount = $cammount
# Node for the camera
onready var camera = $cammount/cammount/DynaRes/Mainviewport/Camera
# Node for minimap camera
onready var minimapcam = $cammount/cammount/DynaRes/MainViewport/Camera/MiniMapViewport/Camera
# Node for fist KinematicBody
var trainhead
# Throttle GUI element
onready var throttle_gui = $Control/Throttle/VSlider
# Speed GUI element
onready var speed_bar = $Control/Throttle/ProgressBar
# Speed progressbar colors
var pb_colors = [preload("res://assets/railroads/progressbar_white.tres"), preload("res://assets/railroads/progressbar_red.tres")]
# Desired driving direction
var ddd = 2
# Echo fader
onready var effect = AudioServer.get_bus_effect(0, 0)

var resolution_scale = 1.0
	
# Called when the node enters the scene tree for the first time.
func _ready():
	cammount.translation = -translation
	#$cammount/cammount/DynaRes/MainViewport/Camera.global_translate(Vector3(0,0,0))
	update_commuters_count()
	if OS.get_name() == "Android":
		resolution_scale = 0.5
	#shrink_resolution(2)
	for i in range(wagons):
		add_wagon(i)
	trainhead = wagon_nodes[0].get_node("KinematicBody").get_node("campoint")
	#minimapcam.global_transform = camera.global_transform
	minimapcam.translate(Vector3(0,0,2000))
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
	for _i in range(index):
		new_wagon.path_queue.append('s')
	wagon_nodes.append(new_wagon)
	add_child(new_wagon)
	new_wagon.set_global_transform(global_transform)
	new_wagon.translation.z -= 4*index

# Called by signal from the first wagon when arriving at new important point on map.
func new_tile_spotted(straight, left, right):
	var wagon = wagon_nodes[0]
	wagon.path_queue.clear()
	
	if ddd == 1 and left:
		wagon.path_queue.append('l')
		if right or straight:
			pass
			#switch_direction(2)
		return
	if ddd == 3 and right:
		wagon.path_queue.append('r')
		if left or straight:
			pass
			#switch_direction(2)
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

# Switch desired driving direction to 1, 2 or 3. Based on user input.
func switch_direction(dir):
	if ddd != dir:
		$Control/Control/SwitchSound.stop()
		$Control/Control/SwitchSound.pitch_scale = 0.5 + (randf()*0.25)
		$Control/Control/SwitchSound.play()
		ddd = dir

func handle_station():
	if speed > 0.0 or not opened:
		return
	for wagon in wagon_nodes:
		if wagon.at_station() and randf() < 1.0/60.0:
			wagon.load_commuter()
	update_commuters_count()

func have_free_space():
	var sum = 0
	for count in commuters_inside:
		sum += count
	if sum >= ((wagons * wagon_capacity) - substracted_space):
		return false
	return true
		

func update_commuters_count():
	$Control/TLCorner/Com1/Label.text = str(commuters_inside[0])
	$Control/TLCorner/Com2/Label.text = str(commuters_inside[1])
	$Control/TLCorner/Com3/Label.text = str(commuters_inside[2])
	$Control/TLCorner/Com4/Label.text = str(commuters_inside[3])
	$Control/TLCorner/Com5/Label.text = str(commuters_inside[4])
	$Control/TLCorner/Com6/Label.text = str(commuters_inside[5])
	var sum = 0
	var cap = (wagons * wagon_capacity) - substracted_space
	for count in commuters_inside:
		sum += count
	$Control/TLCorner/Com7/Label.text = str(round((float(sum)/cap)*100.0)) + "%"
	if sum == cap:
		$Control/TLCorner/Com7/Label.set("custom_colors/font_color", Color8(255,0,0))
	else:
		$Control/TLCorner/Com7/Label.set("custom_colors/font_color", Color8(255,255,255))
	$Control/TLCorner/Money/Label.text = str(money)

# Called 60 times per second to drive the train.
func _physics_process(delta):
	$cammount/cammount/DynaRes/MainViewport.size = OS.window_size * resolution_scale
	if speed == 0.0 and not opened:
		$Control/Control/door.visible = true
	else:
		$Control/Control/door.visible = false
	if speed > 0.0:
		opened = false
	
	handle_station()
	effect.wet -= delta
	if effect.wet < 0.0:
		effect.wet = 0.0
	
	$Control/TLCorner/FPSLabel.text = "FPS: " + str(Performance.get_monitor(0))
	
	
	if Input.is_action_just_pressed("ui_left") and ddd > 1:
		switch_direction(ddd-1)
	if Input.is_action_just_pressed("ui_right") and ddd < 3:
		switch_direction(ddd+1)
		
	if ddd == 1:
		$Control/Control/left.modulate = Color(1,1,1,1)
	else:
		$Control/Control/left.modulate = Color(1,1,1,0.25)
	if ddd == 2:
		$Control/Control/straight.modulate = Color(1,1,1,1)
	else:
		$Control/Control/straight.modulate = Color(1,1,1,0.25)
	if ddd == 3:
		$Control/Control/right.modulate = Color(1,1,1,1)
	else:
		$Control/Control/right.modulate = Color(1,1,1,0.25)
	
	
	if warmup_frames > 0:
		warmup_frames -= 1
		return
	delta += missed_delta
	if delta > 0.03:
		pass
		#print("Low FPS detected!")
		#missed_delta = delta - 0.03
		#delta = 0.03
	if Input.is_action_pressed("ui_up"):
		throttle_gui.value += 0.5*delta
		if throttle_gui.value > 1.0:
			throttle_gui.value = 1.0
	if Input.is_action_pressed("ui_down"):
		throttle_gui.value -= 0.5*delta
	if throttle_gui.value < 0.0:
		throttle_gui.value = 0.0
	throttle = throttle_gui.value
	if throttle < 0.02:
		throttle = 0.0
	
	if throttle > speed + 0.33:
		throttle = speed-(delta/100)
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
			speed -= (brakes * delta)
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
	$cammount/cammount/DynaRes/MainViewport/Camera.global_translate(cammove_vector*delta*2)


func _on_direction_touch(event, dir):
	if event is InputEventScreenTouch and event.pressed:
		switch_direction(dir)


func _on_Viewport_timeout():
	$cammount/cammount/DynaRes/MainViewport/Camera/MiniMapViewport.size = OS.window_size
	$cammount/cammount/DynaRes/MainViewport/Camera/MiniMapViewport.render_target_update_mode = Viewport.UPDATE_ONCE


func _on_door_pressed():
	opened = true
