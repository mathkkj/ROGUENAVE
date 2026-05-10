extends Node2D

var alvo : CharacterBody2D
var tempo_seguindo = 0.2
@onready var particula = $CPUParticles2D

func _process(delta):
	global_position = alvo.position


func _ready() -> void:
	particula.emitting = true
	

	
	
