extends Marker3D
class_name MapChunkAnchorPoint

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var root_node: Node3D = get_parent().get_parent()
var is_occupied: bool = false
var connected_to: MapChunkAnchorPoint = null

func _ready() -> void:
	mesh_instance_3d.queue_free()

#region getter
func is_available() -> bool:
	return not is_occupied
#endregion

#region setter
func mark_occupied() -> void: 
	is_occupied = true

func mark_free():
	is_occupied = false

func set_connection(chunkAnchorPoint: MapChunkAnchorPoint) -> void:
	connected_to = chunkAnchorPoint
	
func free_connection() -> void:
	connected_to = null
#endregion
