extends RigidBody2D

signal collision
var collided
var ramped
var rolling_spin_ramp
var starting_vel
var prev_vel
var vel
var spin_state_changed
var starting_spin 
var contact_vel
var reflected_vector
var spin
var side_spin
var grabbing_timer
var side_spin_timer
var to_grab


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ramped = false
	collided = false
	side_spin = 0
	side_spin_timer = 0
	to_grab = false
	prev_vel = 0
	spin = 0
	starting_vel = Vector2.ZERO
	spin_state_changed = false
	starting_spin = 0
	rolling_spin_ramp = 0
	grabbing_timer = 0

func _physics_process(_delta):
	side_spin = clamp(side_spin, -1, 1)
	# Side spin decay
	side_spin = move_toward(side_spin, 0, 0.001)
	# Apply the side spin on the ball
	if to_grab:
		if side_spin_timer > 0:
			apply_central_impulse(reflected_vector)
			side_spin_timer -= 1
		else:
			to_grab = false
	
	# Keep the velocity when the ball starts rolling (either when shot or when the backspin wore off)
	vel = linear_velocity.length()
	if vel < 5:
		spin_state_changed = false
		starting_spin = 0
		return
		
	if starting_spin < 0:
		if spin == 0:
			spin_state_changed = true
			starting_spin = 0
			set_roll_values()
			
	if spin_state_changed:
		set_roll_values()
		spin_state_changed = false
	
	elif (prev_vel < 5 and vel >= 5):
		set_roll_values()
	prev_vel = vel
	
	# Ignoring very small velocities
	if starting_vel.length() < 150:
		return
		
	# Start ramping up the rolling spin
	if not ramped:
		ramp()
		
	if collided:
		# Apply spin for as long as it must take for the spin to fully grab (20 frames max)
		if grabbing_timer <= 20:
			apply_central_impulse(starting_vel.normalized() * clamp(starting_vel.length(), 100, 900) * 0.008)
			grabbing_timer += 1
		else:
			collided = false
			set_roll_values()
			

func _on_body_entered(body: Node) -> void:
	if linear_velocity.length() > 0.8:
		collided = true
	
	collision.emit(body)
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if side_spin == 0:
			return
		if collider is StaticBody2D:
			to_grab = true
			side_spin_timer = 2
			# Set a different vector for each cushion 
			if str(collider.name) == 'Top Cushion':
				reflected_vector = Vector2(45 * side_spin, 0)
			elif str(collider.name) == 'Bottom Cushion':
				reflected_vector = Vector2(-45 * side_spin, 0)
			elif str(collider.name) == 'Left Cushion':
				reflected_vector = Vector2(0, -45 * side_spin)
			elif str(collider.name) == 'Right Cushion':
				reflected_vector = Vector2(0, 45 * side_spin)
			# Side spin loss after cushion contact
			side_spin *= 0.8

			
func ramp():
	if not starting_vel:
		return
	# Increase the ramper until it reaches 1750 (the maximum starting velocity)
	rolling_spin_ramp += 70
	if grabbing_timer < 20:	
		# The longer it takes for the ramper to reach 1750, the higher the timer will be 
		# so the rolling spin will need more time to fully grab
		grabbing_timer += 1
		
	if rolling_spin_ramp > 1750:
		ramped = true
	

func set_roll_values():
	starting_vel = linear_velocity
	# The harder the shot, smaller the ramp value
	rolling_spin_ramp = 1750 - starting_vel.length()
	grabbing_timer = 0
	ramped = false
