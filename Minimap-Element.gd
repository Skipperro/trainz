extends Spatial

export(String, "Track", "Train", "Station") var type = "Track" 
#var animate_train = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = true
	if type == "Track":
		$track.visible = true
	if type == "Train":
		$train.visible = true
	if type == "Station":
		$station.visible = true
		$station.mesh.surface_get_material(0).albedo_color = get_parent().StationColor
		



