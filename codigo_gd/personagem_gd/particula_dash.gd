extends Node2D


@onready var particula = $CPUParticles2D

func _process(_delta):
	pass


func _ready() -> void:
	particula.emitting = true
	
	

	
	
