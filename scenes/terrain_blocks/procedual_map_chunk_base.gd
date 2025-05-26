extends Node3D
class_name ProcedualMapChunk

@onready var mesh: Node3D = $Mesh
@onready var anchors: Node3D = $Anchors
@onready var collision_check: Area3D = $CollisionCheck

var _cached_bounds: AABB
var _bounds_computed := false


func get_anchor_points() -> Array[MapChunkAnchorPoint]: 
	var anchorPoints: Array[MapChunkAnchorPoint]
	anchorPoints.assign(anchors.get_children().filter(func (x): return x is MapChunkAnchorPoint and x.is_occupied == false).map(func(x): return x as MapChunkAnchorPoint))
	return anchorPoints

func get_foreign_collisions() -> Array:
	var own_children = mesh.get_children()
	var overlapping_bodies = collision_check.get_overlapping_bodies()
	return overlapping_bodies.filter(func(x):
		return !(x in own_children)
	)

func get_global_bounds() -> AABB:
	if _bounds_computed == true:
		return _cached_bounds
	var combined_aabb := AABB()
	var found_first := false

	for child in mesh.get_children():
		if child is MeshInstance3D and child.mesh:
			var local_aabb = child.mesh.get_aabb()
			var global_aabb = transform_aabb(local_aabb, child.global_transform)

			if not found_first:
				combined_aabb = global_aabb
				found_first = true
			else:
				combined_aabb = combined_aabb.merge(global_aabb)
	_cached_bounds = combined_aabb
	_bounds_computed = true
	return combined_aabb
	
func get_combined_shapes() -> Array:
	var shapes = []
	for child in mesh.get_children():
		if child is MeshInstance3D and child.mesh:
			var local_aabb = child.mesh.get_aabb()
			var shape = BoxShape3D.new()
			shape.size = local_aabb.size

			# Build transform: move to global position + center offset
			var shape_transform = child.global_transform.translated(local_aabb.position + local_aabb.size * 0.5)

			shapes.append({ "shape": shape, "transform": shape_transform })
	return shapes

func transform_aabb(aabb: AABB, aabb_transform: Transform3D) -> AABB:
	var points = []
	for i in 8:
		points.append(aabb_transform * aabb.get_endpoint(i))

	var transformed_aabb = AABB(points[0], Vector3.ZERO)
	for i in range(1, 8):
		transformed_aabb = transformed_aabb.expand(points[i])

	return transformed_aabb
