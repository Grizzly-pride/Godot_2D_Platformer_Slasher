extends KinematicBody2D

var dust_scene = preload("res://Objects/Player/Dust_player.tscn") # сцена пыли
var buff_scene = preload("res://Objects/Player/Buffs.tscn") # эффекты бафов



export var squat_speed = 60 # скорость бега 
export var run_speed = 140 # скорость бега 
export var move_speed = 140 # скорость перемещения
export var ladder_speed = 50 # скорость перемещения 
export var acceleration = 10 # разгон
export var slide_speed = 260 # скорость скольжения по земле
export var gravity = 900 # сила гравитации
export var jump_power = 280 # сила первого прыжка 
export var jump_wall = 100 # прыжок от стены 
export var friction = 13 # сила трения по поверхности
export var max_health = 100



const FLOOR_NORMAL = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 3
const SLOPE_TRASHOLD = deg2rad(46)


var velocity = Vector2.ZERO # 2D вектор с начальной координатой 0
var snap_vector = SNAP_DIRECTION * SNAP_LENGTH
var is_hang # схватился за уступ
var move_x # движение по координате x
var move_y # движение по координате y
var climb_up # взобраться на уступ
var climb_down # слезть
var jump_count # количество прыжков по дефолту
var is_hang_right # проверка уступа справа
var is_hang_left # проверка уступа слева
var target # цель куда переместить героя
var ladder_pos # позиция лестницы по x
var now_state # состояние анимации героя


#Для состояния пыли
var dust_stop: bool = false
var dust_jump: bool = false
var dust_landing: bool = false
var dust_jump_wall: bool = false
var dust_landing_wall: bool = false
var dust_start_sliding: bool = false
var dust_hanging: bool = false

#ловить момент состояния пыли
var on_ground: bool = false
var was_ground: bool = false
var on_wall: bool = false
var was_wall: bool = false
var is_run: bool = false
var was_run: bool = false
var was_sliding: bool = false
var was_hanging: bool = false

#Для состояния героя
var is_climb: bool = false # процес взбирания
var can_slide: bool = true # может сскользить
var is_sliding: bool = false # скользит
var is_sit: bool = false # сидеть
var ladder_on: bool = false # тригер лестницы
var ladder_climb: bool = false #герой  может взбираться по лестнице


onready var current_health = max_health #текущее значение жизней 100%
onready var animation_tree = get_node("AnimationTree")
onready var animation = animation_tree.get("parameters/playback") # переменная для дерева анимаций
onready var sprite = $Sprite_player # переменная спрайта
onready var sprite_shadow = $Sprite_shadow # спрайт тени
onready var hang = $Hang # область зацепа
onready var hang_left = $Hang_left # датчик проверки уступа слева
onready var hang_right = $Hang_right # датчик проверки уступа справа
onready var wall_right = $Wall_right # правый датчик проверки любой стены
onready var wall_left = $Wall_left # левый датчик любой стены
onready var grab_right = $Grab_wall_right # правый датчик схватиться за стену
onready var grab_left = $Grab_wall_left # левый датчик схватиться за стену
onready var on_ground1 = $Ground_1  # датчик проверки земли
onready var on_ground2 = $Ground_2 # датчик проверки земли
onready var roof = $Roof # датчик проерки потолка
onready var body_big = $Body_big # область тела в положении стоя
onready var body_small = $Body_small # область тела в положении сидя
onready var new_position_r = $New_Position_R # правая новая позиция
onready var new_position_l = $New_Position_L # левая новая позиция
onready var hp_bar = $Touch_control/HP_bar # прогресс жизней


var player_state = state.Idle # переменная состояния и присвоить состояние ожидания
# словарь состояний
enum state{
Braking,
Landing,
Climb,
Fall,
Hang,
Idle,
Jump,
Run,
Run_Start,
Sit,
Squating,
Start_Slide,
Slide,
Stop_Slide,
Idle_Wall,
Somersault,
Ladder_move_up,
Ladder_idle,
Ladder_move_down}

func _ready():
	$AnimationTree.active = true # активировать дерево анимации при загрузке
	

#*******************************************************************************

func _physics_process(delta:float):
	"""Главный цикл описывающий физику героя"""
	
	if (now_state == "Sit_down" or now_state == "Stand_up" or now_state == "Climb" ) and is_sliding == false:
		velocity.x = 0
		
	if can_slide == true and ladder_climb == false and is_climb == false and !Grab_walls():
		Movement_x() # функция движения по координате x
	if is_climb == false:
		Slide() # функция скольжения по земле
		Squat() # функция сидячего состояния	
	if (now_state != "Grab_the_wall" or now_state != "Jump_on_ladder") and can_slide == true:
		Jump() # функция прыжка
	if ladder_on == true:
		Movement_y() #функция движения по координате y
	Ladder()
	Hang() # функция зацепа
	Climb() # функция подняться на уступ
	Logic_Collision_Shape() # функция логики переключения области тела
	State_logic() # функция состояния героя
	Flip_sprite() # перевернуть спрайт героя
	Animation_update(delta)	
	Dust_logic()
	Gravity(delta) # функция гравитации
	
	
	
#*******************************************************************************

func Movement_x():
	"""Движение по координате X"""

	move_x = Input.get_action_strength("Right") -Input.get_action_strength("Left")
	if move_x != 0: # если кнопки движения влево и вправо нажаты
		velocity.x = move_toward(velocity.x, move_x * move_speed, acceleration)
	elif move_x == 0: # если кнопки не нажаты
		velocity.x = move_toward(velocity.x, 0, friction)
		
#*******************************************************************************
		
func Movement_y():
	"""Движение по координате Y"""
	move_y = Input.get_action_strength("Down") -Input.get_action_strength("Up")
	if move_y != 0 and ladder_climb == true:
		velocity.y = ladder_speed * move_y
	elif move_y == 0 and ladder_climb == true:
		velocity.y = 0
		
#*******************************************************************************

func Ladder():
	"""Переключение на движение по лестнице"""
	if !is_on_floor():
		if ladder_on == true and move_y == -1:
			position.x = ladder_pos
			ladder_climb = true
			velocity.x = 0
	
	if ladder_on == false:
		ladder_climb = false
		
func Get_ladder_position(body):
	"""Получить позицию лестницы"""
	ladder_pos = body

#*******************************************************************************

func Squat():
	"""Функция приседания"""
	if On_Ground():
		if is_sliding == false and is_sit == false and ladder_climb == false:
			if Input.is_action_just_pressed("Down"):
				is_sit = true
		elif is_sliding == false and is_sit == true and ladder_climb == false:
			if Input.is_action_just_pressed("Up"):
				is_sit = false
			
	if !On_Ground():
		is_sit = false
		
	if is_sit == true:
		move_speed = squat_speed
	else:
		move_speed = run_speed

#*******************************************************************************

func Slide():
	"""Функция скольжения"""
	if can_slide == true and On_Ground() and !Grab_walls(): # если могу скользить и на земле но не на стене
		if Input.is_action_just_pressed("Slide"):
			velocity.x = 0 # heroe the hero has a speed of zero
			can_slide = false
			is_sliding = true
			
			# направление скольжения
			if sprite.flip_h == false:
				velocity.x += slide_speed 
			elif sprite.flip_h == true:
				velocity.x -= slide_speed
			
			
			yield(get_tree().create_timer(0.4), "timeout") # отмена скольжения
			velocity.x = 0
			is_sliding = false
			yield(get_tree().create_timer(0.3), "timeout") # задержка перед возможностью повторного скольжения
			can_slide = true
			
	if !On_Ground():
		is_sliding = false
		can_slide = true

#*******************************************************************************

func Jump():
	"""Функция прыжка"""
	
	if On_Ground() or Grab_walls() or ladder_climb == true:
		jump_count = 2
	if  is_sliding == false:
		if Input.is_action_just_pressed("Jump") and jump_count > 0 and !roof.is_colliding():
			#сбросить скорость перед вторым прыжком
			if velocity.y > 0 or jump_count == 1:
				velocity.y = 0
			#логика прыжка
			if is_on_floor() or Grab_walls() or ladder_climb == true:
				velocity.y -= jump_power
				jump_count -= 1
			elif !is_on_floor() and jump_count == 1 and ladder_climb == false:
				velocity.y -= jump_power
				jump_count -= 1
			elif !is_on_floor() and jump_count == 2 and ladder_climb == false:
				velocity.y -= jump_power
				jump_count -= 2
			if ladder_climb == true:
				ladder_climb = false
				ladder_on = false
			if  not is_on_floor() and Grab_right_wall() and is_hang == false:
				velocity.x = -150
				velocity.y -= jump_wall
			if  not is_on_floor() and Grab_left_wall() and is_hang == false:
				velocity.x = 150
				velocity.y -= jump_wall

	#if Input.is_action_just_released("Jump") and velocity.y < 0: # высота прыжка от длительности нажатия кнопку
		#velocity.y = 0

#*******************************************************************************

func Hang():
	"""Функция зацепиться за уступ"""

	is_hang_right = hang_right.is_colliding() == false and wall_right.is_colliding() == true and !On_Ground()
	is_hang_left = hang_left.is_colliding() == false and wall_left.is_colliding() == true and !On_Ground()
	is_hang = velocity.y >= 0 and (is_hang_left or is_hang_right) # переменная зацепился правый или левый датчик истина

	if is_hang_right and body_big.disabled == false: # если правый датчик истина и не сидит то перевернуть спрайт в право
		sprite.flip_h = false
	elif is_hang_left and body_big.disabled == false: # если левый датчик истина и не сидит то перевернуть спрайт в лево
		sprite.flip_h = true

	if is_hang == true and body_big.disabled == false and !climb_down: # если зацепился и состояние героя не сидячее
		hang.disabled = false # активировать область зацепа
	else: # если зацепился и состояние героя не сидячее
		hang.disabled = true # если не истина то отключить область зацепа

#*******************************************************************************

func Climb():
	"""Функция взбирания на платформу"""
	climb_up = Input.is_action_just_pressed("Up")
	if is_climb == false:
		climb_down = Input.is_action_pressed("Down")

	if sprite.flip_h == false:
		target = new_position_r.get_global_position()
	if sprite.flip_h == true:
		target = new_position_l.get_global_position()
		
	if is_on_floor():
		if player_state == state.Hang and velocity.y == 0:
			if climb_up:
				is_climb = true
			if climb_down:
				hang.disabled = true

	if player_state == state.Climb:
		yield(get_tree().create_timer(0.9), "timeout")
		is_climb = false

func Change_position():
	"""Изменение области тела при взбирании на платформу"""
	position = target

#*******************************************************************************

func Grab_walls():
	return Grab_right_wall() or Grab_left_wall()
func Grab_right_wall():
	return grab_right.is_colliding()
func Grab_left_wall():
	return grab_left.is_colliding()

func On_Ground():
	return on_ground1.is_colliding() or on_ground2.is_colliding()

#*******************************************************************************

func Logic_Collision_Shape():
	"""Изменение области тела героя"""
	if On_Ground():
		# Включить и выключить шейпы при скольжении
		if is_sliding == true:
			body_small.disabled = false
			body_big.disabled = true
		# Включить и выключить шейпы при наличии потолка над головой
		elif is_sliding == false and roof.is_colliding():
			is_sit = true
			body_small.disabled = false
			body_big.disabled = true
		# Включить и выключить шейпы при приседании
		elif is_sit == true:
			body_small.disabled = false
			body_big.disabled = true
		else:
			body_small.disabled = true
			body_big.disabled = false
	else:
		body_small.disabled = true
		body_big.disabled = false

#*******************************************************************************

func Gravity(delta):
	"""Описание гравитации героя"""
	if ladder_climb == false:
		velocity.y += gravity* delta# гравитация работает пока герой не повиснет на лестнице
		
	# ограничение скорости падения
	if velocity.y > 700:
		velocity.y = 700 
	# торможение по стене
	if Grab_walls(): 
		velocity.y = move_toward(velocity.y, 0, 80) #торможение по стене
		
	velocity.y = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true, 4, SLOPE_TRASHOLD).y
	#velocity.y = move_and_slide(velocity, Vector2.UP, true).y
#*******************************************************************************

func State_logic():
	"""Логика состояний героя"""
	# movement on ground logic

	if On_Ground():
		if abs(velocity.x) >= run_speed:
			player_state = state.Run
		if abs(velocity.x) <= acceleration:
			player_state = state.Idle
	if On_Ground():
		if move_x != 0:
			if abs(velocity.x) != run_speed and abs(velocity.x) > acceleration:
				player_state = state.Run_Start
		elif move_x == 0:
			if abs(velocity.x) != run_speed and abs(velocity.x) != 0:
				player_state = state.Braking

	# jumping logic
	if !On_Ground():
		if velocity.y > 0:
			player_state = state.Fall
		elif velocity.y < 0:
			player_state = state.Jump
	

	# grab wall logic
	if Grab_walls():
		player_state = state.Idle_Wall

	# sliding on floor logic
	if is_sliding == true and On_Ground():
		player_state = state.Slide

	# sit logic
	if is_sit == true and is_sliding == false:
		if abs(velocity.x) <= acceleration:
			player_state = state.Sit
		elif abs(velocity.x) >= acceleration:
			player_state = state.Squating

	# hang logic
	if hang.disabled == false and is_hang == true:
		player_state = state.Hang

	# climb logic
	if is_climb == true:
		player_state = state.Climb
		
	#somersault logic
	if !is_on_floor():
		if velocity.y < 0 and jump_count == 0:
			player_state = state.Somersault
	
	# ladder logic
	if ladder_climb == true:
		if move_y == -1:
			player_state = state.Ladder_move_up
		elif move_y == 1:
			player_state = state.Ladder_move_down
		elif move_y == 0:
			player_state = state.Ladder_idle
			
	# shadow logic
	if On_Ground():
		sprite_shadow.visible = true
	else:
		sprite_shadow.visible = false

#*******************************************************************************

func Flip_sprite():
	"""Перевернуть спрайт героя относительно его направления движения"""
	# flip sprite logic
	if player_state != state.Hang and player_state != state.Idle_Wall:
		if velocity.x < 0:
			sprite.flip_h = true
			sprite_shadow.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
			sprite_shadow.flip_h = false

#*******************************************************************************

func Animation_update(delta):
	"""Переключение анимация"""

	$AnimationPlayer.advance(delta)

	# state mashine
	match (player_state):
		state.Idle:
			animation.travel("Idle")

		state.Run_Start:
			animation.travel("Run_Start")
	
		state.Run:
			animation.travel("Run")

		state.Braking:
			animation.travel("Braking")

		state.Landing:
			animation.travel("Landing")

		state.Jump:
			animation.travel("Jump")

		state.Fall:
			animation.travel("Fall")

		state.Hang:
			animation.travel("Hang")
	
		state.Climb:
			animation.travel("Climb")
	
		state.Sit:
			animation.travel("Sit")

		state.Squating:
			animation.travel("Squating")

		state.Start_Slide:
			animation.travel("Start_Slide")
	
		state.Slide:
			animation.travel("Slide")
	
		state.Stop_Slide:
			animation.travel("Stop_Slide")
	
		state.Idle_Wall:
			animation.travel("Idle_Wall")
	
		state.Somersault:
			animation.travel("Somersault")
	
		state.Ladder_move_up:
			animation.travel("Ladder_move_up")
		
		state.Ladder_idle:
			animation.travel("Ladder_idle")
		
		state.Ladder_move_down:
			animation.travel("Ladder_move_down")
	
	now_state = animation.get_current_node()
	#print(now_state)

#*******************************************************************************

func Dust_logic():
	"""Функция обработки состояния эффектов пыли"""

	#Прыжок с земли
	on_ground = On_Ground()
	if was_ground == true and on_ground == false and velocity.y<0:
		dust_jump = true
		Creation_dust()
	else:
		dust_jump = false
	
	#Приземление на землю
	if was_ground == false and on_ground == true:
		dust_landing = true
		Creation_dust()
	else:
		dust_landing = false
	was_ground = on_ground

	#Прыжок со стены
	on_wall = Grab_walls()
	if was_wall == true and on_wall == false:
		dust_jump_wall = true
		Creation_dust()
	else:
		dust_jump_wall = false
	
	#Приземление на стену
	if was_wall == false and on_wall == true:
		dust_landing_wall = true
		Creation_dust()
	else:
		dust_landing_wall = false
	was_wall = on_wall
	
	
	#Остановка
	is_run = velocity.x >=acceleration or velocity.x <= -acceleration
	if On_Ground():
		if was_run == true and is_run == false:
			dust_stop = true
			Creation_dust()
		else:
			dust_stop = false
	was_run = is_run
	
	
	#Скольжение старт
	if was_sliding == false and is_sliding == true:
		dust_start_sliding = true
		Creation_dust()
	else:
		dust_start_sliding = false
	was_sliding = is_sliding
		
		
	#Зацеп за уступ
	if velocity.y == 0:
		if was_hanging == false and is_hang == true:
			dust_hanging = true
			Creation_dust()
		else:
			dust_hanging = false
		was_hanging = is_hang

#*******************************************************************************

func Creation_dust():
	
	var dust = dust_scene.instance()
	get_parent().add_child(dust)
	if dust_jump == true:
		dust.dust_state = dust.state.Jump_dust
	elif dust_landing == true:
		dust.dust_state = dust.state.Landing_dust
	elif dust_landing_wall == true:
		dust.dust_state = dust.state.Wall_landing_dust
	elif dust_jump_wall == true:
		dust.dust_state = dust.state.Wall_jump_dust
	elif dust_stop == true:
		dust.dust_state = dust.state.Stop_dust
	elif dust_start_sliding == true:
		dust.dust_state = dust.state.Start_sliding_dust
	elif dust_hanging == true:
		dust.dust_state = dust.state.Hanging_dust
		
		
	dust.global_position = self.global_position + Vector2(0,-15)
	if sprite.flip_h == true:
		dust.animation.flip_h = true
	else:
		dust.animation.flip_h = false
		
#*******************************************************************************
	
	
func Take_damage(amount):
	if current_health > 0:
		current_health -= amount 
		hp_bar.HP_bar_update(current_health, max_health)
	if current_health <= 0:
		Dead()
	
	print(current_health)
	
	
func Take_healing(amount):
	var buff = buff_scene.instance()
	add_child(buff)
	buff.buff_state = buff.state.healling
	buff.global_position = global_position
	$Healing.play()
	
	current_health += amount
		
	if current_health > max_health:
		current_health = max_health
			
	hp_bar.HP_bar_update(current_health, max_health)
	
		
	print(current_health)
	
	
func Dead():
	print("You Dead!!!")
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

