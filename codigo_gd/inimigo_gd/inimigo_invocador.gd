extends Inimigo_Projetil
class_name Inimigo_invocador

var quantidade_de_inimigos := 0
@export var quantidade_max_de_inimigos := 4

@onready var cena_explosao = preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

@export var inimigos_invocados_cenas: Array[PackedScene] = [
	preload("res://cenas_tscn/inimigos_tscn/inimigo_meele_invocado.tscn")
]

@onready var area = $circulo_de_visao
@onready var collision = $circulo_de_visao/CollisionShape2D
@onready var label2 = $Label2

var ja_atirou := false
var inimigos_invocados: Array[Node] = []

enum ESTADOS_INVOCADOR {
	NORMAL,
	INVOCANDO
}

var estado_invocador: ESTADOS_INVOCADOR = ESTADOS_INVOCADOR.NORMAL


func pode_invocar() -> bool:
	return is_instance_valid(alvo) \
		and estado_atual == ESTADOS.CACANDO \
		and estado_distancia == ESTADOS_DISTANCIA.IDEAL \
		and LOS.get_collider() == alvo


func _physics_process(delta: float) -> void:
	if not is_instance_valid(alvo):
		return

	label2.text = str(quantidade_de_inimigos, " ", quantidade_max_de_inimigos)

	mirar()
	check_posicao_alvo()

	if estado_invocador == ESTADOS_INVOCADOR.INVOCANDO:
		velocity = Vector2.ZERO
		super._physics_process(delta)
		return

	super._physics_process(delta)


func _on_atirar_tempo_timeout() -> void:
	if ja_atirou:
		return

	if not pode_invocar():
		return

	var faltando = quantidade_max_de_inimigos - quantidade_de_inimigos

	if faltando <= 0:
		return

	ja_atirou = true
	estado_invocador = ESTADOS_INVOCADOR.INVOCANDO
	velocity = Vector2.ZERO

	for i in range(faltando):
		var cena_escolhida = inimigos_invocados_cenas.pick_random()
		var posicao_invocacao = pegar_pos_borda()

		# cria a explosao
		var explosao = cena_explosao.instantiate()
		explosao.global_position = posicao_invocacao
		explosao.z_index = 100
		get_tree().current_scene.add_child(explosao)
		
		# cria o inimigo logo depois
		var inimigo = cena_escolhida.instantiate()
		inimigo.global_position = posicao_invocacao
		get_tree().current_scene.add_child(inimigo)

		inimigos_invocados.append(inimigo)
		inimigo.tree_exited.connect(invocadinho_morreu.bind(inimigo))

		quantidade_de_inimigos += 1

	estado_invocador = ESTADOS_INVOCADOR.NORMAL
	ja_atirou = false
	atualizar_animacao()

	if quantidade_de_inimigos < quantidade_max_de_inimigos:
		atirar_tempo.start()

func invocadinho_morreu(inimigo: Node) -> void:
	if inimigo in inimigos_invocados:
		inimigos_invocados.erase(inimigo)
		quantidade_de_inimigos -= 1

		if quantidade_de_inimigos < 0:
			quantidade_de_inimigos = 0

		print("tem ainda ", quantidade_de_inimigos, " invocadinhos")

	if not ja_atirou and quantidade_de_inimigos < quantidade_max_de_inimigos:
		atirar_tempo.start()


func limpar_lista_invocados() -> void:
	for inimigo in inimigos_invocados.duplicate():
		if not is_instance_valid(inimigo):
			inimigos_invocados.erase(inimigo)


func pegar_pos_borda() -> Vector2:
	var raio = collision.shape.radius

	var direcao_aleatoria = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	var posicao_borda = direcao_aleatoria * raio

	return global_position + posicao_borda


func check_posicao_alvo():
	var collider = LOS.get_collider()

	if collider == alvo:
		if atirar_tempo.is_stopped():
			atirar_tempo.start()
		return

	if collider != null and collider.is_in_group("inimigos"):
		return


func receber_dano(dano: int) -> void:
	if not is_instance_valid(alvo):
		return

	vida -= dano

	if vida <= 0:
		for inimigo in inimigos_invocados:
			if is_instance_valid(inimigo):
				inimigo.morrer()

		inimigos_invocados.clear()
		quantidade_de_inimigos = 0

		var particula_morte = particula_morte_cena.instantiate()
		particula_morte.position = global_position
		get_tree().current_scene.add_child(particula_morte)

		queue_free()
		
		#apaga todos (nao mexe nisso)
		#for node in get_tree().get_nodes_in_group("inimigos_invocados"):
			#if node.has_method("morrer"):
				#node.morrer()


func atualizar_animacao():
	if estado_atual == ESTADOS.HIT:
		tocar_animacao("hit")
		return

	if estado_invocador == ESTADOS_INVOCADOR.INVOCANDO:
		tocar_animacao("invocando")
		return

	if velocity.length() > 10:
		tocar_animacao("andar")
		return

	tocar_animacao("idle")
