extends CharacterBody2D

@export var velocidade = 350.0
@export var aceleracao = 2750.0
@export var atrito = 1500.0

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")

	if direcao != Vector2.ZERO:
		#da pra tirar o normalized() se precisar
		var velocidade_alvo = direcao.normalized() * velocidade
		velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)

	move_and_slide()
