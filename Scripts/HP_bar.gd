extends TextureProgress

onready var twin = $Tween
onready var HP_bar = $"."

var  precentage_hp
var green = "3b882b"
var orange = "887c2b"
var red = "882b2b"


func _ready():
	pass 
	
func HP_bar_update(current_hp, max_hp):
	precentage_hp = int((float(current_hp) / max_hp) * 100)
	twin.interpolate_property(HP_bar, 'value', value, precentage_hp, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	twin.start()
	
	value = precentage_hp
	
	if precentage_hp >= 60:
		set_tint_progress(green)
	elif precentage_hp <= 60 and precentage_hp >= 25:
		set_tint_progress(orange)
	else:
		set_tint_progress(red)
		



