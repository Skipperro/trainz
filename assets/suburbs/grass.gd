extends MeshInstance

# Probability of spawning a tree
export(float, 0, 1) var tree_chance = 0.75

var tree_meshes = [preload("res://assets/tree-meshes/tree-branched.obj"),
preload("res://assets/tree-meshes/tree-columnar.obj"),
preload("res://assets/tree-meshes/tree-conical.obj"),
preload("res://assets/tree-meshes/tree-open.obj"),
preload("res://assets/tree-meshes/tree-oval.obj"),
preload("res://assets/tree-meshes/tree-pyramidal.obj"),
preload("res://assets/tree-meshes/tree-round.obj"),
preload("res://assets/tree-meshes/tree-spreading.obj")]

var treemat1 = load("res://assets/tree-meshes/tree1.material")
var treemat2 = load("res://assets/tree-meshes/tree2.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if randf() <= tree_chance:
		var tree = $treespawner/tree
		tree.translation.x = (randf() * 6) - 3
		tree.translation.z = (randf() * 6) - 3
		var mesh = tree_meshes[randi()%tree_meshes.size()]
		tree.mesh = mesh
		tree.set_surface_material(0, treemat1)
		tree.set_surface_material(1, treemat2)
		tree.global_rotate(Vector3(0,1,0), randf() * 360)
		$treespawner.visible = true
	else:
		$treespawner.visible = false

