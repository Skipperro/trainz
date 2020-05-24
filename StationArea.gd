extends Area

# Max commuter capacity at the station
export var capacity = 60
# How fast new commuters are generated in seconds
export var cooldown = 10.0
# X of station area
export var area_X = 8.0
# Z of station area
export var area_Z = 1.0
# ID of this station
export var StationID = 0
# Preffered direction as a station ID where commuters want to go from here
export var PrefferedDirection = 0
# Station color
export var StationColor = Color8(255, 0, 0)



# Cooldown timer node
onready var timer = $Timer
# Station area
var area_shape
# List of commuters waiting for the train.
var commuters = []
# Commuter template
var template = preload("res://assets/railroads/commuter.tscn")

func _ready():
	$CollisionShape.shape.extents.x = area_X
	$CollisionShape.shape.extents.z = area_Z
	area_shape = $CollisionShape.shape.extents
	reset_timer()

# Resets cooldown timer that creates new commuters
func reset_timer(extended=0):
	timer.stop()
	timer.wait_time = cooldown + extended
	timer.start()
	
# Removes one commuter (put him in the train)
func kill_commuter():
	reset_timer(20)
	if commuters.size() > 0:
		var ascendant = commuters.pop_front()
		ascendant.queue_free()


func _on_Timer_timeout():
	reset_timer()
	if commuters.size() >= capacity:
		return
	var new_commuter = template.instance()
	add_child(new_commuter)
	new_commuter.translation.y = 0
	new_commuter.translation.x = 0 - (area_shape.x) + (area_shape.x * randf() * 2)
	new_commuter.translation.z = 0 - (area_shape.z) + (area_shape.z * randf() * 2)
	commuters.append(new_commuter)
