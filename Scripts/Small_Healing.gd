extends Node2D

export var healing = 20


func _ready():
	pass 


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		if get_node("../Player").current_health < get_node("../Player").max_health:
			get_node("../Player").Take_healing(healing)
			queue_free()
