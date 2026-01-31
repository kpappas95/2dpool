extends RigidBody2D

signal collision
var collided
var ramped
var ramping_up
var start_roll = false
var rolling_spin = 1
var starting_vel
var stopped = false
var reflected_vector
var spin
var side_spin
var grabbing_timer = 0
var side_spin_timer = 0
var to_grab = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ramped = false
	side_spin = 0
	

func _physics_process(_delta):
	side_spin = clamp(side_spin, -1, 1)
	if not name == "Cue_Ball":
		return
	
	if to_grab:
		if side_spin_timer > 0:
			apply_central_impulse(reflected_vector)
			side_spin_timer -= 1
		else:
			to_grab = false
	
	
	if linear_velocity.length() > 0.8 :
		if stopped:
			starting_vel = linear_velocity
			rolling_spin = 1750 - linear_velocity.length()
			stopped = false
			print(starting_vel)
		if not ramped:
			ramp()
		
		if collided:
			print(starting_vel)
			#print(grabbing_timer)
			if grabbing_timer > 0:
				apply_central_impulse(starting_vel * 0.0002 * linear_velocity.length())
				grabbing_timer -= 0.5
			ramped = false
			grabbing_timer = 0
			collided = false
			rolling_spin = 1
			starting_vel = linear_velocity
			#apply_central_impulse(direction * rolling_spin * 0.023)
	else:
		stopped = true
	
	

func _on_body_entered(body: Node) -> void:

	if linear_velocity.length() > 0.8:
		collided = true
	if grabbing_timer == 0:
		starting_vel = linear_velocity
	collision.emit(body)
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if side_spin == 0:
			return
		if collider is StaticBody2D:
			print(side_spin)
			to_grab = true
			side_spin_timer = 2
			if str(collider.name) == 'Top Cushion':
				reflected_vector = Vector2(45 * side_spin, 0)
			elif str(collider.name) == 'Bottom Cushion':
				reflected_vector = Vector2(-45 * side_spin, 0)
			elif str(collider.name) == 'Left Cushion':
				reflected_vector = Vector2(0, -45 * side_spin)
			elif str(collider.name) == 'Right Cushion':
				reflected_vector = Vector2(0, 45 * side_spin)
			side_spin *= 0.8

			
func ramp():
	if not starting_vel:
		return
	rolling_spin += 70
	grabbing_timer += 1
	#print(grabbing_timer)

	if rolling_spin > 1750:
		ramped = true
	

func apply_roll():
	rolling_spin *= 1.9
	#print(rolling_spin)

	if rolling_spin > 300:
		ramped = true
		if collided:
			collided = false
			ramping_up = true
			reset_rolling_spin()
		ramping_up = false
		ramped = true
	
func reset_rolling_spin():
	rolling_spin = 1
