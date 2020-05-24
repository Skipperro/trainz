extends Area

onready var enabled = false
onready var effect = AudioServer.get_bus_effect(0, 0)

func _on_Area_body_entered(body):
	enabled = true


func _on_Area_body_exited(body):
	enabled = false
	
func _physics_process(delta):
	if enabled:
		if effect.wet < 0.6:
			effect.wet += delta*2
		if effect.wet > 0.6:
			effect.wet = 0.6
