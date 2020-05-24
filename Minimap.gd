extends Control

onready var map = $ColorRect
var mapmode = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_map"):
		mapmode = not mapmode
	if mapmode:
		map.modulate.a += 4*delta
	else:
		map.modulate.a -= 4*delta
	if map.modulate.a > 1.0:
		map.modulate.a = 1.0
	if map.modulate.a < 0.0:
		map.modulate.a = 0.0


func _on_MapButton_pressed():
	mapmode = not mapmode
