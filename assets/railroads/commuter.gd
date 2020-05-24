extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	$body.get("material/0").albedo_color = Color8(randf()*150, randf()*150, randf()*150)

