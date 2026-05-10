extends CharacterBody2D


@onready var label = $Label
@export var camera : Camera2D

@export var velocidade: float = 350.0
@export var aceleracao: float = 2750.0
@export var atrito: float = 1500.0
@export var dash_vel: float = 1300.0

@export var DASH_TIMER: float = 0.10
@export var tempo_recarregamento_dash: float = 1.0

@export_enum("Programador", "Multimidia", "Fullstack") var classe_personagem: int

var pode_dash: bool = true
var tempo_dash: float = 0.0
var recarregar_tempo_dash: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var ultima_direcao_mira: Vector2 = Vector2.RIGHT

var arma = null
var escala_original_arma = Vector2.ONE


var tempo_golpe: float = 0.0
@export var duracao_golpe: float = 0.25
@export var forca_golpe: float = 700.0
@export var impulso_golpe3: float = 1800.0
var direcao_golpe: Vector2 = Vector2.ZERO


@export var cadencia_atirar = 0.25
var tempo_atirar = 0

#estados
var esta_andando: bool = false
var em_dash: bool = false
var em_golpe: bool = false

@onready var cena_armas : Array[PackedScene] = [ 
	preload("res://cenas_tscn/armas/arma1.tscn"),
	preload("res://cenas_tscn/armas/arma_2.tscn")
]

@onready var pivo_arma : Marker2D = get_node("pivo_arma")
@onready var explosao_cena = preload("res://cenas_tscn/explosao.tscn")

#sprite
@onready var sprite = get_node("AnimatedSprite2D")
var lista_sprite_frames : Array[SpriteFrames] = [
	preload("res://tres/spriteframes/prog_sprite_frames.tres"), 
	preload("res://tres/spriteframes/mult_sprite_frames.tres"),
	preload("res://tres/spriteframes/full_sprite_frames.tres")
	]

func _ready() -> void:
	Global.personagem = self
	atualizar_arma()
	

func atualizar_arma():
	match classe_personagem:
		0:
			Global.arma_atual = 0
			sprite.sprite_frames = lista_sprite_frames[0]
			
		1:
			Global.arma_atual = 1
			sprite.sprite_frames = lista_sprite_frames[1]
		2:
			print("arma multidores fullstack")
			sprite.sprite_frames = lista_sprite_frames[2]
	
	if arma != null:
		arma.queue_free()
		arma = null
	
	if Global.arma_atual == null:
		return
	
	if Global.arma_atual < 0 or Global.arma_atual >= cena_armas.size():
		return
	
	if cena_armas[Global.arma_atual] == null:
		return
	 
	arma = cena_armas[Global.arma_atual].instantiate()
	add_child(arma)
	arma.position = pivo_arma.position
	escala_original_arma = arma.scale

	if arma is ArmaMeele:
		arma.connect("golpe_executado", _on_golpe_executado)
		arma.get_node("hitbox").body_entered.connect(_arma_encostou)
		

func obter_direcao_mira_controle() -> Vector2:
	var dir_esq := Input.get_vector("esquerda", "direita", "cima", "baixo")
	var dir_dir := Input.get_vector("esquerdaAnalogicoDireito", "direitaAnalogicoDireito", "cimaAnalogicoDireito", "baixoAnalogicoDireito")

	var direcao_final := dir_dir if dir_dir.length() > 0.2 else dir_esq

	if direcao_final == Vector2.ZERO:
		return Vector2.ZERO

	ultima_direcao_mira = direcao_final
	return ultima_direcao_mira

func _atualizar_ultima_direcao():
	var direcao: Vector2
	
	
	if Global.usando_controle:
		direcao = obter_direcao_mira_controle()
	else:
		direcao = pivo_arma.global_position.direction_to(get_global_mouse_position())
	
	if direcao != Vector2.ZERO:
		ultima_direcao_mira = direcao


func _physics_process(delta: float) -> void:
	if tempo_atirar > 0.0:
		tempo_atirar = tempo_atirar - delta
	
	label.text = str(em_golpe)
	
	_atualizar_ultima_direcao()

	if arma == null or Global.arma_atual == null:
		return

	em_dash = _mecanica_dash(delta)
	if em_dash:
		move_and_slide()
		#z_index = global_position.y
		return

	if em_golpe:
		tempo_golpe -= delta
		
		var t = 1.0 - (tempo_golpe / duracao_golpe)
		var velocidade_atual = forca_golpe * (1.0 - t * t)
		
		velocity = direcao_golpe * velocidade_atual
	
		move_and_slide()
		#z_index = global_position.y
		
		if tempo_golpe <= 0.0:
			em_golpe = false
		
		return
	
	
	
	
	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")
	esta_andando = direcao != Vector2.ZERO
	
	if arma is ArmaMeele and Input.is_action_just_pressed("atacar") and not em_dash and not em_golpe:
		if Global.usando_controle:
			if obter_direcao_mira_controle() == Vector2.ZERO:
				return
		
		if arma.has_method("atacar"):
			arma.atacar()
		_arma_mirar()

	if arma is ArmasRanged:
		_arma_mirar()
		if Input.is_action_pressed("atacar") and tempo_atirar <= 0.0:
			if arma.has_method("atirar"):
				arma.atirar()
				tempo_atirar = cadencia_atirar
	
	if direcao != Vector2.ZERO:
		var velocidade_alvo = direcao.normalized() * velocidade
		velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)
	
	move_and_slide()
	#z_index = global_position.y
	
func _mecanica_dash(delta: float) -> bool:
	if pode_dash and Input.is_action_just_pressed("dash"):
		pode_dash = false
		tempo_dash = DASH_TIMER
		recarregar_tempo_dash = tempo_recarregamento_dash
		
		dash_dir = Input.get_vector("esquerda", "direita", "cima", "baixo")
		velocity = dash_dir.normalized() * dash_vel
		var offset = direcao_golpe * 20
		var explosao = explosao_cena.instantiate()
		explosao.global_position = global_position + offset
		
		##TODO: CRIAR PARTICULA DE DASH 
		#var particula = explosao.get_node("CPUParticles2D")
		#particula.direction = -dash_dir.normalized()
		#explosao.alvo = self
		#get_tree().current_scene.add_child(explosao)
		
		
	if tempo_dash > 0.0:
		tempo_dash = max(0.0, tempo_dash - delta)
		return true
	else:
		if recarregar_tempo_dash > 0.0:
			recarregar_tempo_dash -= delta
		else:
			em_dash = false
			pode_dash = true
	
	return false


func _arma_mirar():
	var posicao_mira: Vector2
	
	if Global.usando_controle:
		var direcao_final := obter_direcao_mira_controle()
		if direcao_final == Vector2.ZERO:
			return
		
		posicao_mira = pivo_arma.global_position + ultima_direcao_mira * 100
	else:
		posicao_mira = get_global_mouse_position()
	
	var direcao_mira := pivo_arma.global_position.direction_to(posicao_mira)
	
	if arma is ArmaMeele:
		var lado := Vector2.ZERO
		var rotacao := 0.0

		if direcao_mira == Vector2.ZERO:
			return

		var angulo := rad_to_deg(direcao_mira.angle())
		if angulo < 0:
			angulo += 360.0

		# dividir o circulo em 8 direções
		match int(round(angulo / 45.0)) % 8:
			0:
				# direita
				lado = Vector2.RIGHT
				rotacao = 0
			1:
				# direita + baixo
				lado = Vector2(1, 1).normalized()
				rotacao = 30
			2:
				# baixo
				lado = Vector2.DOWN
				rotacao = 90
			3:
				# esquerda + baixo
				lado = Vector2(-1, 1).normalized()
				rotacao = 120
			4:
				# esquerda
				lado = Vector2.LEFT
				rotacao = 180
			5:
				# esquerda + cima
				lado = Vector2(-1, -1).normalized()
				rotacao = 220
			6:
				# cima
				lado = Vector2.UP
				rotacao = 270
			7:
				# direita + cima
				lado = Vector2(1, -1).normalized()
				rotacao = -50
		print("eu ataquei para o ", round(lado))
		
		arma.position = round(lado) * 40
		
		#arma.rotation = deg_to_rad(rotacao)
		arma.rotation_degrees = rotacao
		arma.scale.y = escala_original_arma.y
		arma.show_behind_parent = lado.y < 0

	
	else:
		var angulo := direcao_mira.angle()
		var distancia := 60.0
		
		arma.global_position = pivo_arma.global_position + Vector2(cos(angulo), sin(angulo)) * distancia
		arma.rotation = lerp_angle(arma.rotation, angulo, 18.0 * get_process_delta_time())
		arma.scale.y = escala_original_arma.y if direcao_mira.x > 0 else -escala_original_arma.y
		arma.show_behind_parent = direcao_mira.y < 0
		
		

func _on_golpe_executado(golpe: int) -> void:
	em_golpe = true
	tempo_golpe = duracao_golpe
	
	direcao_golpe = ultima_direcao_mira.normalized()
	
	

	match golpe:
		1:
			forca_golpe = 700
		2:
			forca_golpe = 900
		3:
			forca_golpe = 1500
			
			
	var hitbox = arma.get_node("hitbox")
	for body in hitbox.get_overlapping_bodies():
		_arma_encostou(body)
		print(body)


func _arma_encostou(body):
	if body.has_method("aplicar_knockback") and em_golpe:
		#TODO: de acordo com o golpe, mudar o konockback e o shake da camera
		print("to atacando o ", body)
		body.aplicar_knockback(direcao_golpe, 900)
		camera.add_trauma(0.45, round(direcao_golpe))
		
		##RECEBER DANO
		#if body.has_method("receber_dano"):
			#body.receber_dano(25)
		
		#particula
		if body is CharacterBody2D: 
			var offset = direcao_golpe * 20
			var explosao = explosao_cena.instantiate()
			explosao.global_position = body.global_position + offset
			
			var particula = explosao.get_node("CPUParticles2D")
			particula.direction = direcao_golpe
			explosao.alvo = body
			get_tree().current_scene.add_child(explosao)
		
#RECEBE O SINAL DA BALA LÁ NO CODIGO DA ARMA
func _on_bala_acertou(body, direcao, forca):
	if body.has_method("aplicar_knockback"):
		body.aplicar_knockback(direcao, forca)
		
		if body is CharacterBody2D: 
			var offset = direcao * 20
			var explosao = explosao_cena.instantiate()
			explosao.global_position = body.global_position + offset
			
			var particula = explosao.get_node("CPUParticles2D")
			particula.direction = direcao
			explosao.alvo = body
			get_tree().current_scene.add_child(explosao)
