extends RigidBody2D

@export var velocidade = 1000.0
@export var desaceleracao = 2500.0
@onready var explosao_cena = preload("res://cenas_tscn/explosao.tscn")
@onready var sprite = get_node("Sprite2D")
@export var vida = 100
var knockback_force = Vector2.ZERO

func _physics_process(delta: float) -> void:
	
	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)
	
	if vida <= 0:
		queue_free()
	
	

func aplicar_knockback(direcao: Vector2, forca) -> void:
	knockback_force = direcao.normalized() * forca
	#trocar cor
	sprite.modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color(1, 1, 1)

func receber_dano(dano):
	vida -= dano
