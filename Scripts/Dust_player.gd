extends Node2D

enum state{
Jump_dust,
Landing_dust,
Stop_dust,
Wall_landing_dust,
Wall_jump_dust,
Sliding_dust,
Start_sliding_dust,
Hanging_dust}


var dust_state
onready var animation = $AnimatedSprite


func _ready():
	pass

func _process(_delta):
	Animation_update()


func Animation_update():
	"""Переключение анимации"""
	# state mashine
	match (dust_state):
		
		state.Hanging_dust:
			animation.play("Hanging_dust")

		state.Jump_dust:
			animation.play("Jump_dust")

		state.Landing_dust:
			animation.play("Landing_dust")

		state.Stop_dust:
			animation.play("Stop_dust")

		state.Wall_landing_dust:
			animation.play("Wall_landing_dust")
			
		state.Wall_jump_dust:
			animation.play("Wall_jump_dust")
		
		state.Sliding_dust:
			animation.play("Sliding_dust")	

		state.Start_sliding_dust:
			animation.play("Start_sliding_dust")

func _on_AnimatedSprite_animation_finished():
	queue_free()
