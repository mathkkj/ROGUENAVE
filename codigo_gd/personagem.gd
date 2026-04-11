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
var ultima_direcao_mira: Vector2 = Vector2.RIGHT

var arma = null
var arma_index_antigo = -1
var escala_original_arma = Vector2.ONE

@onready var cena_armas : Array[PackedScene] = [ 
	preload("res://cenas_tscn/armas/arma1.tscn"),
	preload("res://cenas_tscn/armas/arma_2.tscn")
]

@onready var cena_armas_coletaveis : Array[PackedScene] = [
	preload("res://cenas_tscn/coletavel/arma_1_coletavel.tscn"),
	preload("res://cenas_tscn/coletavel/arma_2_coletavel.tscn")
]

@onready var pivo_arma : Marker2D = get_node("pivo_arma")

func _ready() -> void:
	atualizar_arma()

func atualizar_arma():
	if arma != null:
		arma.queue_free()
		arma = null
	
	print("arma_atual: ", Global.arma_atual)
	
	if Global.arma_atual == null:
		print("arma_atual está null")
		return
	
	if Global.arma_atual < 0 or Global.arma_atual >= cena_armas.size():
		print("arma fora da array")
		return
	
	
	if cena_armas[Global.arma_atual] == null:
		print("a cena nesse index é null")
		return
	
	arma = cena_armas[Global.arma_atual].instantiate()
	add_child(arma)
	arma.position = pivo_arma.position
	arma_index_antigo = Global.arma_atual
	escala_original_arma = arma.scale 
	print("tentando instanciar arma: ", Global.arma_atual)

func _dropar_arma():
	if arma != null and Global.arma_atual != -1 and Input.is_action_just_pressed("dropar"):
		var drop = cena_armas_coletaveis[Global.arma_atual].instantiate()
		get_parent().add_child(drop)
		
		var direcao_drop = Vector2.RIGHT
		if Global.usando_controle == true:
			direcao_drop = ultima_direcao_mira
		else:
			direcao_drop = (get_global_mouse_position() - global_position).normalized()
		
		drop.global_position = global_position + direcao_drop * 110
		drop.qual_arma_que_coleta = Global.arma_atual
		
		arma.queue_free()
		arma = null
		Global.arma_atual = -1
		arma_index_antigo = -1

func _process(delta: float) -> void:
	
	
	if Global.arma_atual != arma_index_antigo:
		atualizar_arma()
		
	
	if arma == null or Global.arma_atual == null:
		return
	if arma != null:
		_arma_mirar()
	
	_dropar_arma()
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

		#if dash_dir.x != 0:
			#$Sprite2D.flip_h = dash_dir.x > 0

	if tempo_dash > 0.0:
		tempo_dash = max(0.0, tempo_dash - delta)
	else:
		if recarregar_tempo_dash > 0.0:
			recarregar_tempo_dash -= delta
		else:
			pode_dash = true

func _arma_mirar():
	var posicao_mira
	
	if Global.usando_controle == true:
		var direcao_mira := Input.get_vector("esquerda", "direita", "cima", "baixo")
		
		if direcao_mira != Vector2.ZERO:
			ultima_direcao_mira = direcao_mira.normalized()
		
		posicao_mira = pivo_arma.global_position + ultima_direcao_mira * 100
	else:
		posicao_mira = get_global_mouse_position()

	
	var direcao_mira := pivo_arma.global_position.direction_to(posicao_mira)
	arma.global_position = pivo_arma.global_position + direcao_mira * 60
	arma.scale.y = escala_original_arma.y if direcao_mira.x > 0 else -escala_original_arma.y
	arma.show_behind_parent = direcao_mira.y < 0
	arma.look_at(posicao_mira)
