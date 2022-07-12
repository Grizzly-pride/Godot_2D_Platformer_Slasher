extends Area2D

export var damage = 90

func _ready():
	pass
	


func _on_Enemy_body_entered(body):
	if body.is_in_group("Player"):
		get_node("../Player").Take_damage(damage)


