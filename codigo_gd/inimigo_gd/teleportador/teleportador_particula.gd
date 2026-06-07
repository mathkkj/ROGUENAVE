extends Node2D

@onready var particula = get_child(0)

func _ready() -> void:
	particula.emitting = true
	
