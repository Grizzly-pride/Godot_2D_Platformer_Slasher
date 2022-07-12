extends Area2D


func _on_Area2D_body_entered(body):
	if body.has_method("Ladder"):
		get_node("../Player").ladder_on = true
	
		var lader_map_pos = get_node("TileMap").world_to_map(get_node("../Player").position)
		var lader_world_pos_x = get_node("TileMap").map_to_world(lader_map_pos).x +21

		body.Get_ladder_position(lader_world_pos_x)


func _on_Area2D_body_exited(body):
	if body.has_method("Ladder"):
		get_node("../Player").ladder_on = false
		

