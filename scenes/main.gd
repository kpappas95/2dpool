extends Node

@export var ball_scene: PackedScene 


var playing = true
var game_over = false
signal balls_stopped
var signal_emitted = false
var lives = 3
var live_sprites
var cushion_hit = true
var pottet_ball = true
var legal_hit = true
var fouled = false
var scratched = false
var nine_to_reset = false
var ball_images: = []
var balls: = []
var one_ball
var nine_ball
var nine_ball_pos = Vector2.ZERO
var nine_ball_texture
var potted_balls = []
var current_ball = 1
var moving_balls = false
var cue_ball
var vel = 0
var spin = 0
var spin_state = 'neutral'
var rolling_spin = 0.0006
var ramped = false
var cue_ball_collided = false
var impact = false
var ramping_up = false
const START_POS = Vector2(380, 214)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_images()
	new_game()
	$PoolTable/Pockets.body_entered.connect(potted_ball)
	live_sprites = $Lives.get_children()

func load_images():
	for i in range(1, 17, 1):
		var filename = str("res://Images/ball_", i, ".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

func new_game():
	playing  = true
	game_over = false
	generate_balls()

func generate_balls():
	reset_cue_ball()
	var nineball_rack = [1, 2, 3, 2, 1]
	var current_ball_number: int = 0
	var diam = 16
	
	for col in range(5):
		for row in range(nineball_rack[col]):
			var b = ball_scene.instantiate()
			b.collision.connect(cushion_collision)
			b.name = "Ball_%d" % (current_ball_number + 1)
			var pos = Vector2(685 + (col * diam), 225 + (row * diam) - (nineball_rack[col]) * diam / 2)
			add_child(b)
			b.position = pos
			balls.append(b)
			b.get_node("Sprite2D").texture = ball_images[current_ball_number]
			current_ball_number += 1
	rack_balls()
		
func disable_ball_physics():
	for ball in balls:
		ball.sleeping = true
		
func enable_ball_physics():
	for ball in balls:
		ball.sleeping = false
		
func rack_balls():
	disable_ball_physics()
	var rack_positions: Array[Vector2] = []
	for b in balls:

		rack_positions.append(b.position)
	one_ball = balls.pop_at(0)
	nine_ball = balls.pop_at(-1)
	nine_ball_pos = nine_ball.global_position
	nine_ball_texture = nine_ball.get_node("Sprite2D").texture
	balls.shuffle()
	balls.push_front(one_ball)
	balls.insert(4, nine_ball)


	for i in range(balls.size()):
		balls[i].position = rack_positions[i]
		balls[i].linear_velocity = Vector2.ZERO
		balls[i].angular_velocity = 0
		balls[i].sleeping = true
		
func reset_cue_ball():
	if is_instance_valid(cue_ball):
		cue_ball.queue_free()
		cue_ball = null
	cue_ball = ball_scene.instantiate()
	
	cue_ball.global_position.x = -500
	cue_ball.name = "Cue_Ball"
	add_child(cue_ball)
	cue_ball.collision.connect(_on_ball_collision)	
	cue_ball.get_node("Sprite2D").texture = ball_images.back()
	reset_cue()
	playing = true
	
func reset_nine_ball():
	if is_instance_valid(nine_ball):
		balls.erase(nine_ball)
		potted_balls.erase(nine_ball)
		nine_ball.queue_free()
		nine_ball = null  
	nine_ball = ball_scene.instantiate()
	nine_ball.name = "Ball_9"
	nine_ball.get_node("Sprite2D").texture = nine_ball_texture
	nine_ball.global_position = nine_ball_pos
	balls.append(nine_ball)
	add_child(nine_ball)
	get_node("Ball Colors/Ball_9").visible = true
	$"Ball Colors/outline".visible = true
	
func reset_cue():
	
	$Cue.reset_cue(cue_ball.position)

func _process(_delta: float) -> void:
	var sounds = get_tree().get_nodes_in_group("sound")
	
	print(playing)
	var sounds_playing = 0
	$Cue.sounds_playing = false
	for sound in sounds:
		if sound.is_playing():
			sounds_playing += 1
			$Cue.sounds_playing = true
			playing = false
	if sounds_playing == 0:
		if game_over:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		playing = true
		$Cue.sounds_playing = false
	if $Spin/Area2D.goes_for_spin:
		$Cue.selecting_spin = true
	else:
		$Cue.selecting_spin = false
	
	moving_balls = false

	if cue_ball.linear_velocity.length() > 0.8:
		
		cue_ball.apply_central_impulse(vel * spin)
		apply_spin()
		if spin < 0:
			spin_state = 'back'
		elif spin == 0:
			spin_state = 'neutral'
		else:
			spin_state = 'top'
		moving_balls = true
	else:
		spin = 0
	for ball in balls:
		if ball:
			if ball.linear_velocity.length() > 0.8:
				moving_balls = true
	if moving_balls:
		$Cue.hide()
		moving_balls = false
	else:
		if scratched or cue_ball.global_position.x == -500:
			cue_ball.global_position = START_POS
		if nine_to_reset:
			call_deferred("reset_nine_ball")
			pseudo_shoot()
			
		if not $Cue.shooting:
			if not signal_emitted:
				balls_stopped.emit()
				signal_emitted = true
			reset_cue()
			$Cue.show()
			$Cue.moving_balls = false
	
func potted_ball(body):
	$"Pot sound".play()
	if body == cue_ball:
		scratched = true
		call_deferred("reset_cue_ball")
	else:
		pottet_ball = true
		if str(body.name)[-1] == str(current_ball):
			current_ball += 1
			for ball in potted_balls:
				if "Ball_" + str(current_ball) == ball.name:
					current_ball += 1
		get_node("Ball Colors/" + body.name).visible = false
		if body == nine_ball:
			if fouled or scratched:
				nine_to_reset = true
			if scratched:
				call_deferred("reset_nine_ball")
			
			else:
				potted_balls.append(body)
				body.call_deferred("set_linear_velocity", Vector2.ZERO)
				body.call_deferred("set_angular_velocity", 0.0)
				body.call_deferred("set_sleeping", true)
				body.set_deferred("freeze", true)	
				body.global_position.x = -500
				$"Ball Colors/outline".visible = false
				
		else:
			potted_balls.append(body)
			body.call_deferred("set_linear_velocity", Vector2.ZERO)
			body.call_deferred("set_angular_velocity", 0.0)
			body.call_deferred("set_sleeping", true)
			body.set_deferred("freeze", true)	
			body.global_position.x = -500

		
		set_lowest_ball()

func _on_cue_shoot(force) -> void:
	
	playing = true
	nine_to_reset = false
	legal_hit = false
	cushion_hit = false
	pottet_ball = false
	fouled = false
	scratched = false
	cue_ball_collided = false
	signal_emitted = false
	spin = $Spin/Area2D.spin_y
	ramped = false
	spin_state = 'neutral'
	if spin > 0:
		spin_state = 'top'
	elif spin < 0:
		spin_state = 'back'
		
	rolling_spin = 1.0006
	vel = force
	
	$Cue.hide()
	$Cue.moving_balls = true
	
	enable_ball_physics()
	cue_ball.apply_central_impulse(vel)
	$"Cue Hit sound".volume_db = min(0 - (1750 - vel.length())/100, 0)
	$"Cue Hit sound".play()
	$Cue.reset_cue(cue_ball.position)
	$Spin/Area2D.reset_spin()

	ramping_up = true
	
func apply_spin():
	var step = 0.245
	if spin > 0:
		step = 0.205
	
	spin = move_toward(spin, 0, step/$Cue.power)
	
	if spin >= 0:
		if not ramped:
			apply_roll()
		var cvel = vel
		if spin_state == 'back':
			cvel = vel * -1
		else:
			cvel = vel
		
		cue_ball.apply_central_impulse(cvel * rolling_spin * 0.000023)
		if cue_ball_collided:
			rolling_spin = move_toward(rolling_spin, 0, 9)	
	

func apply_roll():
	if ramping_up:
		rolling_spin *= 1.9
		if rolling_spin > 300:
			ramped = true
			if cue_ball_collided:
				cue_ball_collided = false
				ramping_up = true
				reset_rolling_spin()
			ramping_up = false
			ramped = true
		
func reset_rolling_spin():
	rolling_spin = 1.0006

func _on_ball_collision(body) -> void:
	if not body.name == "Cue_Ball":
		if is_instance_of(body, RigidBody2D):
			ramped = true
			(body.get_node("Area2D/AudioStreamPlayer").volume_db) = 0
		if not fouled:
			if is_instance_of(body, RigidBody2D):
				if not str(body.name)[-1] == str(current_ball):
					fouled = true
				else:
					legal_hit = true
	if is_instance_of(body, StaticBody2D):
		rolling_spin /= 1.2
		if legal_hit:
			cushion_hit = true
	cue_ball_collided = true
		
func cushion_collision(body):
	if is_instance_of(body, StaticBody2D):
		if legal_hit:
			cushion_hit = true
			
func set_lowest_ball():
	if current_ball <= 9:
		$"Ball Colors/outline".global_position = get_node("Ball Colors/Ball_" + str(current_ball)).global_position
	
func shot_validation():
	if scratched:
		call_deferred("reset_cue_ball")
		legal_hit = false
	if not cushion_hit:
		if not pottet_ball:
			legal_hit = false
	
	if not legal_hit:
		print("You fouled")
		lives -= 1
		live_sprites[lives].visible = false
		if lives == 0:
			print("GAME OVER")
			$"Lose sound".play()
			game_over = true
	else:
		for ball in potted_balls:
			if ball.name == "Ball_9":
				if scratched or fouled:
					nine_ball.call_deferred("set_sleeping", false)
					nine_ball.set_deferred("freeze", false)
				
				print("YOU WIN!")
				$"Win sound".play()
				game_over = true

func _on_balls_stopped() -> void:
	shot_validation()

func pseudo_shoot():
	scratched = false
	nine_to_reset = false
	signal_emitted = false
	spin = $Spin/Area2D.spin_y
	rolling_spin = 1.0006
	$Cue.hide()
	$Cue.moving_balls = true
	enable_ball_physics()
	$Cue.reset_cue(cue_ball.position)
	$Spin/Area2D.reset_spin()

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/arxikh.tscn")
