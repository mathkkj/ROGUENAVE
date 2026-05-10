extends RigidBody2D

#var speed = 500
#
#func _physics_process(delta):
	#var force = Vector2.ZERO
	#if Input.is_action_pressed("ui_right"):
		#force.x += 1
	#if Input.is_action_pressed("ui_left"):
		#force.x -= 1
	#if Input.is_action_pressed("ui_down"):
		#force.y += 1
	#if Input.is_action_pressed("ui_up"):
		#force.y -= 1
	#
	## Apply force directly to the rigid body
	#apply_central_force(force.normalized() * speed)
