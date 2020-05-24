extends Spatial

var houses = [preload("res://assets/suburbs/house-carport-garage.tscn"),
preload("res://assets/suburbs/house-carport-left.tscn"),
preload("res://assets/suburbs/house-carport-right.tscn"),
preload("res://assets/suburbs/house-carport-smallA.tscn"),
preload("res://assets/suburbs/house-carport-smallB.tscn"),
preload("res://assets/suburbs/house-country.tscn"),
preload("res://assets/suburbs/house-mid.tscn"),
preload("res://assets/suburbs/house-modern.tscn")]


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var house = houses[randi()%houses.size()].instance()
	add_child(house)
	$placeholder.queue_free()
