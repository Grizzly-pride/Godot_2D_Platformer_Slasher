extends Node2D

enum state{
healling
}


var buff_state
onready var animation = $AnimatedSprite



func _ready():
	pass

func _process(_delta):
	Animation_update()


func Animation_update():
	"""Переключение анимации"""
	# state mashine
	match (buff_state):
		state.healling:
			animation.play("Healling")


func _on_AnimatedSprite_animation_finished():
	queue_free()
