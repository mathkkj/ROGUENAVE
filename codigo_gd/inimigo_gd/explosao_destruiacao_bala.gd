extends Node2D

@onready var particula = get_node("CPUParticles2D")

func _ready() -> void:
	particula.emitting = true
