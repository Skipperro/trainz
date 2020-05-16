extends Spatial

# Model for the wagon.
export(String, "Driver", "Coach") var type = "Driver" 
# Size of the grid of the map.
export(float) var grid_size = 4.0
# Signal informing whole train that the head reached new location.
signal spot_new_tile(straight, left, right)
# Signal informing whole train that the head decided where to go next.
signal direction_chosen(dir)
# List of directions that head took, so that other wagons can follow same path.
var path_queue = []
# Node for path.
var n_path
# Node for wagon KinematicBody.
var n_wagon
# Node for PathFollower used to guide the wagon.
var n_follower
# Node for RayCast used to detect distance to wagon ahead.
var ray
# If this is the first wagon with driver inside.
var head = false

# Called when the node enters the scene tree for the first time.
func _ready():
	n_path = $Path
	n_wagon = $KinematicBody
	n_follower = $Path/PathFollow
	ray = $KinematicBody/RayCast
	n_path.curve = Curve3D.new()	# Make sure it's unique for each wagon.
	set_type(type)

# Rotates wagon mesh 180 degree. Useful for last wagon if it's driver type.
func invert_wagon():
	$KinematicBody/driver_wagon.rotation_degrees.y += 180

# Set visible mesh of the wagon.
func set_type(newtype):
	if newtype == "Coach":
		$KinematicBody/driver_wagon.visible = false
		$KinematicBody/coach_wagon.visible = true
	else:
		$KinematicBody/driver_wagon.visible = true
		$KinematicBody/coach_wagon.visible = false
	type = newtype

# Set if it's the first wagon or not.
func set_head(value):
	head = value
	$KinematicBody/CollisionShape.disabled = not value

# Main function to move wagon along its path at 60 Hz.
func move_forward(distance):
	if not head:
		# Check if distance between wagons is correct and adjust if needed.
		if ray.is_colliding():
			var origin = ray.global_transform.origin
			var collision_point = ray.get_collision_point()
			var ray_distance = origin.distance_to(collision_point)
			distance = distance + ((ray_distance-1)*0.05)
	var total_distance = float(n_path.curve.get_baked_length())
	if n_follower.offset + distance >= total_distance - grid_size:
		if path_queue.empty():
			n_follower.offset = total_distance - grid_size
		else:
			var overshot = float((n_follower.offset + distance) - (total_distance - grid_size))
			n_follower.offset = total_distance - grid_size
			plot_course(path_queue.pop_front())
			n_follower.offset = overshot
	else:
		n_follower.offset += distance
	n_wagon.set_global_transform(n_follower.global_transform)

# Creates new path curve to follow after reaching the edge of the grid tile.
func plot_course(direction):
	if head:
		emit_signal("direction_chosen", direction)
	
	# Smooth out some imperfection created by PathFollow.
	n_wagon.translation.x = round(n_wagon.translation.x)
	n_wagon.translation.z = round(n_wagon.translation.z)
	n_wagon.scale = Vector3(1,1,1)
	
	# Operate in nice 0-360 range of rotation.
	if n_wagon.rotation_degrees.y > 360.0:
		n_wagon.rotation_degrees.y -= 360.0
	if n_wagon.rotation_degrees.y < 0.0:
		n_wagon.rotation_degrees.y += 360.0
	
	# Smooth out some imperfection created by PathFollow.
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
		n_path.curve.add_point(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,grid_size/2))
	else:
		n_path.curve.add_point(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,grid_size))
	$Path/marker1.set_global_transform(n_wagon.global_transform)
	$Path/marker3.set_global_transform($KinematicBody/middle.global_transform)
	
	if direction == "l":
		n_path.curve.add_point(Vector3(grid_size,0,grid_size))
		n_path.curve.add_point(Vector3(grid_size*2,0,grid_size))
		$Path/marker2.set_global_transform($KinematicBody/left.global_transform)
	if direction == "s":
		n_path.curve.add_point(Vector3(0,0,grid_size))
		n_path.curve.add_point(Vector3(0,0,grid_size*2))
		$Path/marker2.set_global_transform($KinematicBody/straight.global_transform)
	if direction == "r":
		n_path.curve.add_point(Vector3(-grid_size,0,grid_size))
		n_path.curve.add_point(Vector3(-grid_size*2,0,grid_size))
		$Path/marker2.set_global_transform($KinematicBody/right.global_transform)

# Signal informing whole train that the head reached new location.
func spot_new_tile(straight, left, right):
	if head:
		emit_signal("spot_new_tile", straight, left, right)
