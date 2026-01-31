extends Node

@export var ball_scene: PackedScene 


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
var balls_remaining
var one_ball
var nine_ball
var nine_ball_pos = Vector2.ZERO
var nine_ball_texture
var potted_balls = []
var current_ball = 1
var moving_balls = false
var cue_ball
var vel = 0
#var cue_ball.spin = 0
var side_spin = 0
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
	game_over = false
	generate_balls()

func generate_balls():
	reset_cue_ball()
	# Initialize rack positions
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
	balls_remaining = balls
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
	# Rack one ball at the front and nine ball at the center of the rack (other balls rack randomly)
	one_ball = balls.pop_at(0)
	nine_ball = balls.pop_at(-1)
	nine_ball_pos = one_ball.global_position
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
	# Move the cue ball out of the screen
	cue_ball.global_position.x = -500
	cue_ball.name = "Cue_Ball"
	cue_ball.spin = 0
	cue_ball.side_spin = 0
	add_child(cue_ball)
	cue_ball.collision.connect(_on_ball_collision)	
	cue_ball.get_node("Sprite2D").texture = ball_images.back()
	reset_cue()
	
func reset_nine_ball():
	if is_instance_valid(nine_ball):
		balls.erase(nine_ball)
		potted_balls.erase(nine_ball)
		nine_ball.queue_free()
		nine_ball = null  
	nine_ball = ball_scene.instantiate()
	nine_ball.name = "Ball_9"
	nine_ball.get_node("Sprite2D").texture = nine_ball_texture
	#Respawn nine ball at the spot (the spawn spot is the racking position of the one ball)
	nine_ball.global_position = nine_ball_pos
	balls.append(nine_ball)
	add_child(nine_ball)
	get_node("Ball Colors/Ball_9").visible = true
	$"Ball Colors/outline".visible = true
	
func reset_cue():
	$Cue.reset_cue(cue_ball.position)

func _process(_delta: float) -> void:
	
	var sounds = get_tree().get_nodes_in_group("sound")
	
	var sounds_playing = 0
	$Cue.sounds_playing = false
	# Check for sounds still playing
	for sound in sounds:
		if sound.is_playing():
			sounds_playing += 1
			$Cue.sounds_playing = true
	if sounds_playing == 0:
		# Restart the game when all sounds have stopped
		if game_over:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	
	moving_balls = false
	# Check if the cue ball is still moving
	if cue_ball.linear_velocity.length() > 0.8:
		# Apply the cue_ball.spin forces to the cue ball every frame
		cue_ball.apply_central_impulse(vel * cue_ball.spin)
		apply_spin()
		moving_balls = true
	else:
		pass#cue_ball.spin = 0
	# Check if all the balls have stopped
	for ball in balls:
		if ball:
			if ball.linear_velocity.length() > 0.8:
				moving_balls = true
	if moving_balls:
		$Cue.hide()
		#moving_balls = false
	else:
		# Respawn cue ball or nine ball when the shot is completed to avoid premature collisions
		if scratched or cue_ball.global_position.x == -500:
			cue_ball.global_position = START_POS
		if nine_to_reset:
			call_deferred("reset_nine_ball")
			pseudo_shoot() # Nine ball respawns smaller for some reason so that fixes it
			
		if not $Cue.shooting:
			if not signal_emitted:
				# Emit a signal to validate the shot after it's completed
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
		
		# Remove the ball from the list of the remaining balls
		get_node("Ball Colors/" + body.name).visible = false
		if body == nine_ball:
			if fouled or scratched:
				nine_to_reset = true
			if scratched:
				call_deferred("reset_nine_ball")
			else:
				hide_ball(body)
				# Hide the white outline when the nine ball is potted
				$"Ball Colors/outline".visible = false
		else:
			hide_ball(body)
		# Update the remaining balls and highlight the lowest ball on the table
		for ball in potted_balls:
			balls_remaining.erase(ball)
			balls_remaining.sort_custom(func(a, b):return int(str(a.name)[-1]) < int(str(b.name)[-1]))
			current_ball = int(str(balls_remaining[0].name)[-1])
		set_lowest_ball()

func hide_ball(ball):
	potted_balls.append(ball)
	ball.call_deferred("set_linear_velocity", Vector2.ZERO)
	ball.call_deferred("set_angular_velocity", 0.0)
	ball.call_deferred("set_sleeping", true)
	ball.set_deferred("freeze", true)	
	ball.global_position.x = -500
	
func _on_cue_shoot(force) -> void:
	nine_to_reset = false
	legal_hit = false
	cushion_hit = false
	pottet_ball = false
	fouled = false
	scratched = false
	cue_ball_collided = false
	signal_emitted = false
	# Get the amount of the spin on the X and Y axis
	cue_ball.side_spin = $Spin/Area2D.spin_x
	cue_ball.spin = $Spin/Area2D.spin_y
	#cue_ball.starting_vel = force
	
	$Cue.hide()
	$Cue.moving_balls = true
	
	enable_ball_physics()
	# Shoot
	vel = force
	cue_ball.apply_central_impulse(vel)
	$"Cue Hit sound".volume_db = min(0 - (1750 - vel.length())/100, 0)
	$"Cue Hit sound".play()
	$Cue.reset_cue(cue_ball.position)
	$Spin/Area2D.reset_spin()
	
func apply_spin():
	var step = 0.295
	if cue_ball.spin > 0:
		step = 0.265

	# Spin decay
	cue_ball.spin = move_toward(cue_ball.spin, 0, step/$Cue.power)	
	

func _on_ball_collision(body) -> void:
	# Cue ball contact with another ball:
	if is_instance_of(body, RigidBody2D):
		ramped = true
		if not fouled:
			# Check for illegal first hit
			if not str(body.name)[-1] == str(current_ball):
				fouled = true
			else:
				legal_hit = true
	# Cue ball contact with cushion
	if is_instance_of(body, StaticBody2D):

		rolling_spin /= 1.2
		if legal_hit:
			cushion_hit = true
	cue_ball_collided = true
		
func cushion_collision(body):
	# Other ball contact with cushion
	if is_instance_of(body, StaticBody2D):
		if legal_hit:
			cushion_hit = true
			
func set_lowest_ball():
	# Move the whit outline to indicate the lowest numbered ball
	if current_ball <= 9:
		$"Ball Colors/outline".global_position = get_node("Ball Colors/Ball_" + str(current_ball)).global_position
	
func shot_validation():
	# Check for a foul shot
	if scratched:
		call_deferred("reset_cue_ball")
		legal_hit = false
	if not cushion_hit:
		if not pottet_ball:
			legal_hit = false
	
	if not legal_hit:
		print("You fouled")
		# Reduce player's lives
		lives -= 1
		live_sprites[lives].visible = false
		if lives == 0:
			print("GAME OVER")
			$"Lose sound".play()
			game_over = true
	else:
		# Check if the nine ball is potted
		for ball in potted_balls:
			if ball.name == "Ball_9":
				# Respawn nine ball if the player fouled
				if scratched or fouled:
					nine_ball.call_deferred("set_sleeping", false)
					nine_ball.set_deferred("freeze", false)
				else:
					print("YOU WIN!")
					$"Win sound".play()
					game_over = true

func _on_balls_stopped() -> void:
	shot_validation()

func pseudo_shoot():
	scratched = false
	nine_to_reset = false
	signal_emitted = false
	$Cue.hide()
	$Cue.moving_balls = true
	enable_ball_physics()
	$Cue.reset_cue(cue_ball.position)
	$Spin/Area2D.reset_spin()

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/arxikh.tscn")
