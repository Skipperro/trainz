extends Spatial

# Model for the wagon.
export(String, "Driver", "Coach") var type = "Driver" 
#signal request_directions()
signal spot_new_tile(straight, left, right)
signal direction_chosen(dir)

var path_queue = []

var n_path
var n_wagon
var n_follower
var ray
var puller
var head = false
var curve

func _ready():
	n_path = $Path
	n_wagon = $KinematicBody
	n_follower = $Path/PathFollow
	ray = $KinematicBody/RayCast
	n_path.curve = Curve3D.new()
	curve = n_path.curve
	
	#n_path.set_global_transform(Transform(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), Vector3(0,0,0)))
	#$Path.rotation_degrees.y -= rotation_degrees.y
	
	set_type(type)

func invert_wagon():
	$KinematicBody/driver_wagon.rotation_degrees.y += 180

func set_type(newtype):
	if newtype == "Coach":
		$KinematicBody/driver_wagon.visible = false
		$KinematicBody/coach_wagon.visible = true
	else:
		$KinematicBody/driver_wagon.visible = true
		$KinematicBody/coach_wagon.visible = false
	type = newtype

func set_head(value):
	head = value
	$KinematicBody/CollisionShape.disabled = not value

func move_forward(distance):
	if not head:
		if ray.is_colliding():
			var origin = ray.global_transform.origin
			var collision_point = ray.get_collision_point()
			var ray_distance = origin.distance_to(collision_point)
			distance = distance + ((ray_distance-1)*0.05)
	var total_distance = float(n_path.curve.get_baked_length())
	if n_follower.offset + distance >= total_distance - 4.0:
		if path_queue.empty():
			n_follower.offset = total_distance - 4.0
			print("Queue size error: " + name)
		else:
			var overshot = float((n_follower.offset + distance) - total_distance - 4.0)
			n_follower.offset = total_distance - 4.0
			plot_course(path_queue.pop_front())
			n_follower.offset = overshot
	else:
		n_follower.offset += distance
	n_wagon.set_global_transform(n_follower.global_transform)
	#n_wagon.rotation_degrees.y += 90*20*1/(2*PI)

func plot_course(direction):
	if head:
		#print("direction chosen: " + name)
		emit_signal("direction_chosen", direction)
	#var wagon_gpos = n_wagon.global_transform.origin
	#var wagon_grot = n_wagon.global_transform.basis.get_euler()
	#wagon_grot = Vector3(rad2deg(wagon_grot.x), rad2deg(wagon_grot.y), rad2deg(wagon_grot.z))
	
	#n_wagon.rotation_degrees.y = round(n_wagon.rotation_degrees.y)
	n_wagon.translation.x = round(n_wagon.translation.x)
	n_wagon.translation.z = round(n_wagon.translation.z)
	n_wagon.scale = Vector3(1,1,1)
	
	if n_wagon.rotation_degrees.y > 360.0:
		n_wagon.rotation_degrees.y -= 360.0
	if n_wagon.rotation_degrees.y < 0.0:
		n_wagon.rotation_degrees.y += 360.0
	
	if abs(n_wagon.rotation_degrees.y) > 330 or abs(n_wagon.rotation_degrees.y) < 30:
		n_wagon.rotation_degrees.y = 0
	if abs(n_wagon.rotation_degrees.y) > 150 and abs(n_wagon.rotation_degrees.y) < 210:
		n_wagon.rotation_degrees.y = 180
	if abs(n_wagon.rotation_degrees.y) > 60 and abs(n_wagon.rotation_degrees.y) < 120:
		n_wagon.rotation_degrees.y = 90
	if abs(n_wagon.rotation_degrees.y) > 240 and abs(n_wagon.rotation_degrees.y) < 300:
		n_wagon.rotation_degrees.y = 270
	
	

	n_path.curve.clear_points()
	n_path.set_global_transform(n_wagon.global_transform)
	n_path.translation.x = round(n_path.translation.x)
	n_path.translation.z = round(n_path.translation.z)
	n_path.rotation_degrees.y = round(n_path.rotation_degrees.y)
	if direction == "s":
		n_path.curve.add_point(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,2))
	else:
		n_path.curve.add_point(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,4))
	$Path/marker1.set_global_transform(n_wagon.global_transform)
	$Path/marker3.set_global_transform($KinematicBody/middle.global_transform)
	
	if direction == "l":
		n_path.curve.add_point(Vector3(4,0,4))
		n_path.curve.add_point(Vector3(8,0,4))
		$Path/marker2.set_global_transform($KinematicBody/left.global_transform)
	if direction == "s":
		n_path.curve.add_point(Vector3(0,0,4))
		n_path.curve.add_point(Vector3(0,0,8))
		$Path/marker2.set_global_transform($KinematicBody/straight.global_transform)
	if direction == "r":
		n_path.curve.add_point(Vector3(-4,0,4))
		n_path.curve.add_point(Vector3(-8,0,4))
		$Path/marker2.set_global_transform($KinematicBody/right.global_transform)
	
	#print("Course plotted")

func spot_new_tile(straight, left, right):
	if head:
		#print("area spoted: " + name)
		emit_signal("spot_new_tile", straight, left, right)
