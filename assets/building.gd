extends MeshInstance

export var LightOn = false
var lights

var material_day = globalmaterials.m_day
var material_night = globalmaterials.m_night
var LastLightState = false

func _ready():
	lights = $lights

func _physics_process(delta):
	if LightOn == false and LastLightState == true:
		lights.visible = false
		material_override = material_day
	if LightOn == true and LastLightState == false:
		lights.visible = true
		material_override = material_night
	LastLightState = LightOn
