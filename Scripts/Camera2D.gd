extends Camera2D

onready var player = get_parent()

func _ready():
	Engine.set_target_fps(Engine.get_iterations_per_second())

	# Лимиты камеры
	var tilemap_rect = get_parent().get_parent().get_node("Platforms").get_used_rect()
	var tilemap_cell_size = get_parent().get_parent().get_node("Platforms").cell_size
	limit_left = tilemap_rect.position.x * tilemap_cell_size.x
	limit_right = tilemap_rect.end.x * tilemap_cell_size.x
	limit_top = tilemap_rect.position.y * tilemap_cell_size.y
	limit_bottom = tilemap_rect.end.y * tilemap_cell_size.y
	
	global_position = player.global_position

func _process(delta):

	#Смещение камеры в ту сторону куда смотрит герой
	var sprite = get_parent().sprite
	if sprite.flip_h == false:
		position.x += 70*delta
		if position.x >= 60:
			position.x = 60
	elif sprite.flip_h == true:
		position.x -= 70*delta
		if position.x <= -60:
			position.x = -60
