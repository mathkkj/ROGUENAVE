extends CharacterBody2D

@export var vida = 6

@onready var label = $Label
@onready var label2 = $Label2
@export var camera : Camera2D

@export var velocidade: float = 350.0
@export var aceleracao: float = 2750.0
@export var atrito: float = 1500.0
@export var dash_vel: float = 1300.0

@export var DASH_TIMER: float = 0.10
@export var tempo_recarregamento_dash: float = 0.5

@export_enum("Programador", "Multimidia", "Fullstack") var classe_personagem: int

var pode_dash: bool = true
var tempo_dash: float = 0.0
var recarregar_tempo_dash: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var ultima_direcao_mira: Vector2 = Vector2.RIGHT
var direcao_mira : Vector2

var arma = null
var escala_original_arma = Vector2.ONE


var tempo_golpe: float = 0.0
@export var duracao_golpe: float = 0.25
@export var forca_golpe: float = 700.0
@export var impulso_golpe3: float = 1800.0
var direcao_golpe: Vector2 = Vector2.ZERO


@export var cadencia_atirar = 0.25
@export var tempo_atirar = 0

var stamina_total : int
var stamina = 100
var descanso = 30
var stamina_por_acao = 40
var pode_descansar : bool
var stamina_por_ataque = 25

#estados
var esta_andando: bool = false
var em_dash: bool = false
var em_golpe: bool = false
var atirando: bool = false

@onready var cena_armas : Array[PackedScene] = [ 
	preload("res://cenas_tscn/armas/arma1.tscn"),
	preload("res://cenas_tscn/armas/arma_2.tscn")
]

@onready var pivo_arma : Marker2D = get_node("pivo_arma")
@onready var pivo_machado : Marker2D = get_node("pivo_machado")
@onready var explosao_cena = preload("res://cenas_tscn/explosao.tscn")

#sprite
@onready var sprite = get_node("AnimatedSprite2D")
var lista_sprite_frames : Array[SpriteFrames] = [
	preload("res://tres/spriteframes/prog_sprite_frames.tres"), 
	preload("res://tres/spriteframes/mult_sprite_frames.tres"),
	preload("res://tres/spriteframes/full_sprite_frames.tres")
	]

@onready var offset_pd = get_node("offset_pixel_dash")
@onready var particula_dash = preload("res://cenas_tscn/particula_dash.tscn")

@onready var ghost_node = preload("res://cenas_tscn/personagem/ghost_sprite.tscn")
@onready var ghost_timer = get_node("ghost timer")

func perder_vida(dano, direcao_projetil, forca) -> float:
	Input.start_joy_vibration(0, 1.0, 1.0, 0.2) 
	print(direcao_projetil)
	camera.add_trauma(0.4, round(direcao_projetil))
	aplicar_knockback(direcao_projetil, forca)
	_particula_instancia(self, direcao_projetil)
	vida -= dano
	get_tree().paused = true
	#taca a animacao
	await get_tree().create_timer(0.2, true).timeout
	get_tree().paused = false
	return vida

func _ready() -> void:
	
	Global.personagem = self
	atualizar_dados()
	

func atualizar_dados():
	match classe_personagem:
		0:
			Global.arma_atual = 0
			sprite.sprite_frames = lista_sprite_frames[0]
			stamina_total = 100
			stamina = stamina_total
			vida = 100
		
		1:
			Global.arma_atual = 1
			sprite.sprite_frames = lista_sprite_frames[1]
			stamina_total = 150
			stamina = stamina_total
			vida = 150
		
		2:
			print("arma multidores fullstack")
			sprite.sprite_frames = lista_sprite_frames[2]
	
	pode_descansar = true
	
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
	match Global.arma_atual:
		0:
			arma.position = pivo_arma.position
		1:
			arma.position = pivo_machado.position
	
	escala_original_arma = arma.scale

	if arma is ArmaMeele:
		arma.connect("golpe_executado", _on_golpe_executado)
		arma.get_node("hitbox").body_entered.connect(_arma_encostou)
	if arma is ArmasRanged:
		atirando = arma.pode_atirar

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
	if vida <= 0:
		queue_free()
	
	label2.text = str(stamina, vida)
	
	_stamina(delta)
	
	_tempo_atirar(delta)
	
	label.text = str(em_golpe, atirando, pode_dash, esta_andando)
	
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
	var sprite_arma = arma.get_node("Sprite2D")
	
	
	var angulo_em_graus_mira = rad_to_deg(ultima_direcao_mira.angle())
	
	##FLIP SPRITE
	sprite.flip_h = false
	if abs(int(angulo_em_graus_mira) % 360) >= 90 and abs(int(angulo_em_graus_mira) % 360) <= 270:
		#print("cu")
		sprite.flip_h = true
		
		
	esta_andando = direcao != Vector2.ZERO
	
	if arma is ArmaMeele and Input.is_action_just_pressed("atacar") and not em_dash and not em_golpe and stamina >= stamina_por_ataque:
		if Global.usando_controle:
			if obter_direcao_mira_controle() == Vector2.ZERO:
				return
		_arma_mirar()
		if arma.has_method("atacar"):
			
			arma.atacar()
	
		
		

	if arma is ArmasRanged:
		atirando = arma.atirando
		_arma_mirar()
	
		
		
		if Input.is_action_pressed("atacar") and tempo_atirar <= 0.0:
			
			
			if arma.has_method("atirar"):
				atirando = true
				#print(direcao_mira)
				
				arma.atirar()
				
				##recoil
				#if arma.pode_atirar and not em_dash:
					#velocity = -direcao_mira.normalized() * 100
					#move_and_slide()
				
				
				tempo_atirar = cadencia_atirar
				
		elif tempo_atirar >= 0:
			atirando = false
			
		
	var intensidade = direcao.length()
	if direcao != Vector2.ZERO:
		var velocidade_alvo = direcao.normalized() * velocidade * intensidade
		velocity = velocity.move_toward(velocidade_alvo, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)
	
	move_and_slide()
	#z_index = global_position.y
	
	
func add_ghost():
	var ghost = ghost_node.instantiate()

	ghost.global_position = global_position
	
	# copia o frame atual
	ghost.sprite_frames = sprite.sprite_frames
	ghost.animation = sprite.animation
	ghost.frame = sprite.frame


	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale
	

	get_tree().current_scene.add_child(ghost)
	


func _on_ghost_timer_timeout():
	add_ghost()

func _mecanica_dash(delta: float) -> bool:
	if pode_dash and Input.is_action_just_pressed("dash") and esta_andando and not atirando and stamina >= stamina_por_acao:
		stamina -= stamina_por_acao
		pode_dash = false
		pode_descansar = false
		tempo_dash = DASH_TIMER
		recarregar_tempo_dash = tempo_recarregamento_dash
		
		dash_dir = Input.get_vector("esquerda", "direita", "cima", "baixo")
		velocity = dash_dir.normalized() * dash_vel
		
		ghost_timer.start()
		#add_ghost()
		Input.start_joy_vibration(0, 1.0, 1.0, 0.2)
		return true

	
	if tempo_dash > 0.0:
		tempo_dash -= delta
		
		
		if tempo_dash <= 0.0:
			parar_efeitos_visuais_dash()
			
		return true 

	
	if recarregar_tempo_dash > 0.0:
		recarregar_tempo_dash -= delta
		if recarregar_tempo_dash <= 0.0:
			pode_dash = true
		
	
	return false 

func parar_efeitos_visuais_dash():
	z_index = 0
	pode_descansar = true
	await get_tree().create_timer(0.25).timeout
	ghost_timer.stop()


func _arma_mirar():
	
	
	var posicao_mira: Vector2
	
	if Global.usando_controle:
		var direcao_final := obter_direcao_mira_controle()
		if direcao_final == Vector2.ZERO:
			return
		
		posicao_mira = pivo_arma.global_position + ultima_direcao_mira * 100
	else:
		posicao_mira = get_global_mouse_position()
	
	direcao_mira = pivo_arma.global_position.direction_to(posicao_mira)
	
	if arma is ArmaMeele:
		var lado := Vector2.ZERO
		var rotacao := 0.0

		if direcao_mira == Vector2.ZERO:
			return

		var angulo := rad_to_deg(direcao_mira.angle())
		if angulo < 0:
			angulo += 360.0
		var offset_lado = 80
		# dividir o circulo em 8 direções
		match int(round(angulo / 45.0)) % 8:
			0:
				# direita
				lado = Vector2.RIGHT
				rotacao = 0
				
			1:
				# direita + baixo
				lado = Vector2(1, 1).normalized()
				rotacao = 45
				
			2:
				# baixo
				lado = Vector2.DOWN
				rotacao = 90
				
			3:
				# esquerda + baixo
				lado = Vector2(-1, 1).normalized()
				rotacao = 135
				
			4:
				# esquerda
				lado = Vector2.LEFT
				rotacao = 180
				
			5:
				# esquerda + cima
				lado = Vector2(-1, -1).normalized()
				rotacao = 225
				
			6:
				# cima
				lado = Vector2.UP
				rotacao = 270
				
			7:
				# direita + cima
				lado = Vector2(1, -1).normalized()
				rotacao = 315
				
		print("eu ataquei para o ", lado)
		
		
		arma.position = pivo_machado.position + lado * offset_lado
		arma.rotation = deg_to_rad(rotacao)
		#arma.rotation_degrees = rotacao
		arma.scale.y = escala_original_arma.y
		#arma.show_behind_parent = lado.y < 0

	else:
		var angulo = direcao_mira.angle()
		var distancia = 20
		
		arma.global_position = pivo_arma.global_position + Vector2(cos(angulo), sin(angulo)) * distancia
		arma.rotation = lerp_angle(arma.rotation, angulo, 18.0 * get_process_delta_time())
		arma.scale.y = escala_original_arma.y if direcao_mira.x > 0 else -escala_original_arma.y
		#arma.show_behind_parent = direcao_mira.y < 0

func _on_golpe_executado(golpe: int) -> void:
	em_golpe = true
	tempo_golpe = duracao_golpe
	
	direcao_golpe = ultima_direcao_mira.normalized()
	
	

	match golpe:
		1:
			forca_golpe = 700
			stamina -= stamina_por_ataque
		2:
			forca_golpe = 900
			stamina -= stamina_por_ataque 
		3:
			forca_golpe = 1500
			stamina -= stamina_por_ataque
			
			
	var hitbox = arma.get_node("hitbox")
	for body in hitbox.get_overlapping_bodies():
		_arma_encostou(body)
		print(body)

func _arma_encostou(body):
	if body.has_method("aplicar_knockback") and em_golpe:
		arma.get_node("hitbox").set_deferred("monitoring", false) 
		#TODO: de acordo com o golpe, mudar o konockback e o shake da camera
		print("to atacando o ", body)
		body.aplicar_knockback(direcao_golpe, 900)
		
		
		##RECEBER DANO
		#if body.has_method("receber_dano"):
			#body.receber_dano(25)
		
		#particula e se for um personagem
		if body is CharacterBody2D:
			Input.start_joy_vibration(0, 1.0, 1.0, 0.2) 
			#camera.add_trauma(0.4, round(direcao_golpe))
			
			_particula_instancia(body, direcao_golpe)
	if body.is_in_group("projetil_inimigo") and em_golpe:
		pass
		
#RECEBE O SINAL DA BALA LÁ NO CODIGO DA ARMA
func _on_bala_acertou(body, direcao, forca):
	if body.has_method("aplicar_knockback"):
		body.aplicar_knockback(direcao, forca)
		Input.start_joy_vibration(0, 1.0, 1.0, 0.1)
		camera.add_trauma(0.1, round(direcao))
		if body is CharacterBody2D:
			_particula_instancia(body, direcao)
		
func _particula_instancia(body, direcao):
		print(body, direcao)
		#var sprite = body.get_node("Sprite2D")
		#if sprite == null:
			#return
#
		#var textura = sprite.texture
		#if textura == null:
			#return

		#var img = textura.get_image()
		#var cor_dominante = img.get_pixel(0, 0)

		var explosao = explosao_cena.instantiate()
		#explosao.modulate = cor_dominante
		explosao.global_position = body.global_position + (direcao * 20)
		
		explosao.alvo = body

		var particula = explosao.get_node("CPUParticles2D")
		particula.direction = direcao

		get_tree().current_scene.add_child(explosao)
			
			
func _stamina(delta) -> void:
	if pode_descansar and stamina < stamina_total:
		stamina = min(stamina_total, stamina + descanso * delta)
	
		
func _tempo_atirar(delta) -> void:
	if tempo_atirar > 0.0:
		tempo_atirar = tempo_atirar - delta

func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	
	velocity = direcao.normalized() * forca

	sprite.modulate = Color(10, 10, 10)

	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color.WHITE
