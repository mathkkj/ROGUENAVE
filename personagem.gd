extends CharacterBody2D

@export var velocidade: float = 350.0
@export var aceleracao: float = 2750.0
@export var atrito: float = 1500.0
@export var dash_vel: float = 1300.0

@export var DASH_TIMER: float = 0.10
@export var tempo_recarregamento_dash: float = 1.0

var pode_dash: bool = true
var tempo_dash: float = 0.0
var recarregar_tempo_dash: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")

	if direcao != Vector2.ZERO:
		#da pra tirar o normalized() se precisar
		var velocidade_alvo = direcao.normalized() * velocidade
		velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)
	
	_mecanica_dash(delta)
	move_and_slide()

func _mecanica_dash(delta: float) -> void:
	if pode_dash and Input.is_action_just_pressed("dash"):
		pode_dash = false
		tempo_dash = DASH_TIMER
		recarregar_tempo_dash = tempo_recarregamento_dash
		
		#ACHEI RUIM BOTAR O ANALOGICO DIREITO OU O MOUSE PARA A DIREÇÃO DO DASH
		#if Global.usando_controle == false:
			#dash_dir = global_position.direction_to(get_global_mouse_position())
		#else:
			#dash_dir = Input.get_vector("esquerdaAnalogicoDireito", "direitaAnalogicoDireito", "cimaAnalogicoDireito", "baixoAnalogicoDireito")
		dash_dir = Input.get_vector("esquerda", "direita", "cima", "baixo")
		velocity = dash_dir * dash_vel

		if dash_dir.x != 0:
			$Sprite2D.flip_h = dash_dir.x > 0

	if tempo_dash > 0.0:
		tempo_dash = max(0.0, tempo_dash - delta)
	else:
		if recarregar_tempo_dash > 0.0:
			recarregar_tempo_dash -= delta
		else:
			pode_dash = true
	
