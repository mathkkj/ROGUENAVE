extends Node

@export var arma_atual = -1

var usando_controle = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		usando_controle = false
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.2: #deadzone
			usando_controle = true
	elif event is InputEventJoypadButton:
		usando_controle = true
