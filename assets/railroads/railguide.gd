extends Spatial

# Called if train arrives at the location (Area).
func _Area_entered(body, straight, left, right):
	body.get_parent().spot_new_tile(straight, left, right)
