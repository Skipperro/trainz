extends Spatial

func _Area_entered(body, straight, left, right):
	#body.get_parent().straight = straight
	#body.get_parent().left = left
	#body.get_parent().right = right
	body.get_parent().spot_new_tile(straight, left, right)
