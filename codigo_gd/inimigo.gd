extends CharacterBody2D
class_name Inimigo



signal dano_processado



@export var desaceleracao: float = 2500.0
@export var speed: float = 100.0
@export var alvo: CharacterBody2D
@export var max_speed := 300.0
@export var max_accel := 1200.0

@onready var particula_morte_cena = preload("res://cenas_tscn/inimigos_tscn/particula_morte.tscn")
@onready var explosao_cena = preload("res://cenas_tscn/explosao.tscn")

@export var vida: int
@export var escudo: int

var knockback_force: Vector2 = Vector2.ZERO

@onready var atirar_tempo = get_node("atirar_tempo")

@onready var sprite := $Sprite2D


var ultima_direcao := Vector2.ZERO
var tempo_memoria := 0.0

@onready var arr_cast: Array[RayCast2D] = [
	get_node("Raycast/RayDireita"),
	get_node("Raycast/RayBaixoDireita"),
	get_node("Raycast/RayBaixo"),
	get_node("Raycast/RayBaixoEsquerda"),
	get_node("Raycast/RayEsquerda"),
	get_node("Raycast/RayCimaEsquerda"),
	get_node("Raycast/RayCima"),
	get_node("Raycast/RayCimaDireita"),
]


enum ESTADOS {
	CACANDO,
	ATIRANDO,
	HIT,
}

var estado_atual: ESTADOS = ESTADOS.CACANDO


#func escolher_direcao(direcao_alvo: Vector2) -> Vector2:
	#var melhor_direcao := Vector2.ZERO
	#var melhor_pontuacao := -INF
	#
	#for i in range(arr_cast.size()):
		#var ray = arr_cast[i]
		#var esq = arr_cast[(i - 1 + arr_cast.size()) % arr_cast.size()]
		#var dir = arr_cast[(i + 1) % arr_cast.size()]
#
		#ray.force_raycast_update()
		#
		###SISTEMA DE PONTUACAO PARA PEGAR O MELHOR RAY
		#var direcao = ray.target_position.normalized()
		#var pontuacao := 0.0
		## estabilidade
		##da mais pontuacao de forma gradual a posicao diferente da ultima
		#if ultima_direcao != Vector2.ZERO:
			#pontuacao += direcao.dot(ultima_direcao) * 3
			#
		#
		#var alinhamento = direcao.dot(direcao_alvo) #linha pro alvo
		#
		## colisão
		#if ray.is_colliding():
			#var dist = ray.get_collision_point().distance_to(ray.global_position)
			#alinhamento *= 0.5
			#pontuacao -= (1/ max(dist, 0.1)) * 4
		#else:
			#pontuacao += 2.0
			#
		#pontuacao += alinhamento * 6
		## detectar parede longa
		#var bloqueados = 0
		#
			#
		#
		#if ray.is_colliding():
			#bloqueados += 1
		#if esq.is_colliding():
			#bloqueados += 1
		#if dir.is_colliding():
			#bloqueados += 1
	#
		#if bloqueados >= 1:
			#pontuacao *= 0.1
		#
		#
		#if pontuacao > melhor_pontuacao:
			#melhor_pontuacao = pontuacao
			#melhor_direcao = direcao
#
	#if melhor_direcao == Vector2.ZERO:
		#return direcao_alvo
#
	#ultima_direcao = melhor_direcao.normalized()
#
	#return ultima_direcao


func escolher_dir(direcao_alvo: Vector2, delta: float) -> Vector2:
	tempo_memoria -= delta

	var melhor_score := -INF
	var melhor_direcao := ultima_direcao

	for i in range(arr_cast.size()):
		var ray: RayCast2D = arr_cast[i]
		var dir = ray.target_position.normalized()
		var score = dir.dot(direcao_alvo)
		
		# memoria da ultima direcao pra nao trocar de diracao toda hora
		if ultima_direcao != Vector2.ZERO:
			score += dir.dot(ultima_direcao) * 1
		
		
		if ray.is_colliding():

			# direcao da parede (basicamente)
			var normal = ray.get_collision_normal() 
			score += normal.dot(direcao_alvo) * 3.0
			
			#peguei a tangente por conta de serem perpendiculares
			var tangente_esquerda = Vector2(-normal.y, normal.x)
			var tangente_direita = Vector2(normal.y, -normal.x)

			# escolhe tangente melhor
			var score_esquerda = tangente_esquerda.dot(direcao_alvo)
			var score_direita = tangente_direita.dot(direcao_alvo)
			
			#mudar a tangente dependendo da pontuacao
			var tangente = tangente_esquerda
			if score_direita > score_esquerda:
				tangente = tangente_direita

			# favorece deslizar na parede
			score += tangente.dot(direcao_alvo) * 4.0

			# penalidade da colisão
			if ray.get_collider() != null:
				
				if ray.get_collider().is_in_group("inimigos") or ray.get_collider().is_in_group("inimigos_invocados"):
					score -= 6.0
				else:
					score -= 4.0

		
		# ray da esquerda e direita
		var ray_esquerda: RayCast2D = arr_cast[(i - 1 + arr_cast.size()) % arr_cast.size()]
		var ray_direita: RayCast2D = arr_cast[(i + 1) % arr_cast.size()]
		#score do ray da esquerda e direita
		if ray_esquerda.is_colliding():
			score -= 1.0
		if ray_direita.is_colliding():
			score -= 1.0

		# MELHOR DIREÇÃO
		if score > melhor_score:
			melhor_score = score
			melhor_direcao = dir
		
		#print(inventario)
	# atualizar os valores e resetar a memoria
	if tempo_memoria <= 0.0:
		ultima_direcao = melhor_direcao
		tempo_memoria = 0.1
	
	return melhor_direcao





#func cachear_cor():
	#var sprite := $Sprite2D
	#var img = sprite.texture.get_image()
	#img.resize(1, 1, Image.INTERPOLATE_NEAREST)
	#cor_dominante = img.get_pixel(0, 0)

func gerar_steering(direcao_path) -> Vector2:
	
	var desired_velocity = direcao_path * max_speed
	# steering force 
	var steering = desired_velocity - velocity
	return steering

func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return
	
	var direcao_para_alvo: Vector2 = (alvo.global_position - global_position).normalized()
	var direcao_path: Vector2 = escolher_dir(direcao_para_alvo, delta)

	var steering = gerar_steering(direcao_path)
	steering = steering.limit_length(max_accel * delta)

	knockback_force = knockback_force.move_toward(Vector2.ZERO, desaceleracao * delta)
	
	match estado_atual:
		ESTADOS.CACANDO:
			velocity += steering

		ESTADOS.HIT:
			velocity = knockback_force

	move_and_slide()

	if estado_atual == ESTADOS.HIT:
		empurrar_inimigos_colididos()


func empurrar_inimigos_colididos() -> void:
	var direcao_empurrao := velocity.normalized()
	if direcao_empurrao == Vector2.ZERO:
		return

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var outro = col.get_collider()

		if outro != null and outro is Inimigo:
			if outro == self:
				continue

			var forca_empurrao = max(knockback_force.length() * 1, 80.0)
			outro.aplicar_knockback(direcao_empurrao, forca_empurrao)


func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	estado_atual = ESTADOS.HIT
	knockback_force = direcao.normalized() * forca

	sprite.modulate = Color(10, 10, 10)

	await get_tree().create_timer(0.15).timeout
	estado_atual = ESTADOS.CACANDO
	sprite.modulate = Color.WHITE

func receber_dano(dano: int) -> void:
	if escudo <= 0:
		vida -= dano
	else:
		escudo -= dano
	if vida <= 0:
			var particula_morte = particula_morte_cena.instantiate()
			particula_morte.position = global_position
			get_tree().current_scene.add_child(particula_morte)
			queue_free()
	dano_processado.emit()

func _ready() -> void:
	alvo = Global.personagem

func receber_buff(velocidade, escudo, duracao):
	pass
