extends Node3D
class_name ProceduralMap

@onready var chunks: Node3D = $chunks

@onready var map_chunk_templates := [
		preload("res://scenes/terrain_blocks/procedual_map_chunk_base.tscn"),
		preload("res://scenes/terrain_blocks/procedual_map_chunk_base2.tscn")
	]
var map_chunks: Array[ProcedualMapChunk] = []

func _ready() -> void:
	create_map()

func create_map() -> void:
	var template = RngManager.get_random_element(map_chunk_templates)
	var new_chunk := template.instantiate() as ProcedualMapChunk
	chunks.add_child(new_chunk)
	map_chunks.append(new_chunk)
	#
	for i in range(50):
		await create_new_chunk()
		#await get_tree().create_timer(0.5).timeout
		await get_tree().physics_frame

func create_new_chunk() -> void:
	if map_chunk_templates.is_empty() or map_chunks.is_empty():
		push_warning("No templates or base chunks available.")
		return

	var chunk_placed = false

	while chunk_placed == false:
		var template = RngManager.get_random_element(map_chunk_templates)
		var from_chunk = RngManager.get_random_element(map_chunks)
		var open_anchors = from_chunk.get_anchor_points()
		RngManager.array_shuffle(open_anchors)

		while not open_anchors.is_empty():
			var old_anchor = open_anchors.pop_front()
			if old_anchor == null:
				continue

			# Instance the chunk temporarily
			var new_chunk := template.instantiate() as ProcedualMapChunk
			new_chunk.visible = false
			chunks.add_child(new_chunk)

			var new_anchor =  RngManager.get_random_element(new_chunk.get_anchor_points())
			
			if new_anchor == null:
				new_chunk.queue_free()
				continue

			# Align chunk
			align_chunk_to_anchor(new_chunk, new_anchor, old_anchor)
						
			var is_colliding = await check_is_colliding(new_chunk)

			if is_colliding == false:
				# Valid placement
				new_chunk.visible = true
				map_chunks.append(new_chunk)
				old_anchor.mark_occupied()
				new_anchor.mark_occupied()
				chunk_placed = true
				break
			else:
				new_chunk.queue_free()
				if open_anchors.is_empty():
					break


func align_chunk_to_anchor(new_chunk: Node3D, new_anchor: MapChunkAnchorPoint, old_anchor: MapChunkAnchorPoint) -> void:
	#var target_direction = rad_to_deg(old_anchor.global_rotation.y) + 180 % 360
	var target_direction = fposmod(rad_to_deg(old_anchor.global_rotation.y) + 180, 360)

	var needed_rotation = (target_direction - rad_to_deg(new_anchor.global_rotation.y))
	new_chunk.rotate_y(deg_to_rad(needed_rotation))
	# Offset from new chunk's origin to its anchor
	var offset_to_target_position = old_anchor.global_position - new_anchor.global_position
	# Target position for the new chunk: place its anchor at the old one’s position

	new_chunk.global_transform.origin += offset_to_target_position

func check_is_colliding(new_chunk: Node3D) -> bool:	
	var aabb: AABB = new_chunk.get_global_bounds()
	var shape = BoxShape3D.new()
	shape.size = aabb.size
	
	var shape_cast = ShapeCast3D.new()
	shape_cast.enabled = true
	shape_cast.collide_with_bodies = true
	shape_cast.max_results = 1
	shape_cast.shape = shape
	shape_cast.debug_shape_custom_color = Color.RED
	shape_cast.rotation = new_chunk.rotation
	shape_cast.target_position = Vector3(0, 0, 0)
	
	new_chunk.add_child(shape_cast)
	
	#shape_cast.force_update_transform()
	shape_cast.force_shapecast_update()
	
	var is_colliding = shape_cast.is_colliding()

	#shape_cast.queue_free()
	return is_colliding
			
func visualize_aabb(bounds: AABB):
	var debug_box := MeshInstance3D.new()
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = bounds.size
	debug_box.mesh = cube_mesh
	debug_box.global_transform.origin = bounds.position + bounds.size * 0.5
	debug_box.material_override = StandardMaterial3D.new()
	debug_box.material_override.albedo_color = Color(1, 0, 0, 0.3)  # semi-transparent red
	debug_box.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_box.material_override.flags_transparent = true
	debug_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	get_tree().current_scene.add_child(debug_box)

	# Optional: Auto-remove after a few seconds
	debug_box.set_meta("debug", true)
	await get_tree().create_timer(2.0).timeout
	if debug_box.is_inside_tree():
		debug_box.queue_free()

func visualize_query(query: PhysicsShapeQueryParameters3D, size: Vector3):
	var debug_box = MeshInstance3D.new()
	
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = size
	debug_box.mesh = cube_mesh
	
	# Create a transparent material
	debug_box.material_override = StandardMaterial3D.new()
	debug_box.material_override.albedo_color = Color(1, 0, 0, 0.3)  # semi-transparent red
	debug_box.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_box.material_override.flags_transparent = true
	debug_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	debug_box.transform = query.transform
	
	get_tree().current_scene.add_child(debug_box)
	
	# Optional: remove after 1 second
	await get_tree().create_timer(1.0).timeout
	debug_box.queue_free()
