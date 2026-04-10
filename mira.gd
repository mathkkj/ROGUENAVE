extends Sprite2D

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if Global.usando_controle == true:
		visible = false
	else: 
		visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
