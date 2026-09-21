extends Inimigo_meele
class_name Boss


var invulneravel := false


@onready var linha_ioio: Line2D = get_node("Line2D")
@onready var ioio_cena: PackedScene = preload("res://cenas_tscn/inimigos_tscn/boss_tscn/fullstack_tscn/ataque/ioio_ataque.tscn")
@onready var ray_los = get_node("RayLOS")
@onready var area_bloqueio: Area2D = get_node("Bloqueio")

@export var efeito_ataque_cena := preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")


@export var inimigos_invocados_cenas: Array[PackedScene] = [
	preload("res://cenas_tscn/inimigos_tscn/dummys_tscn/dummy.tscn")
]

@export var quantidade_max_invocados := 6
@export var quantidade_invocada := 3
@export var raio_invocacao := 100.0

var inimigos_invocados: Array[Node] = []


var ioios_ativos: Array[Node] = []


signal fase_2_iniciar
signal dialogo_finalizado


@onready var texto_distancia2 = get_node("Label2")
@onready var texto_dialogo = get_node("texto")


@export var dialogo: Dialogue
@export var limite_dialogo: int = -1

var escrevendo := false
var pular_animacao := false
var dialogo_ocorrendo := false

@export var indice := 0


@onready var canvas_layer = get_node("CanvasLayer")
@onready var barra_vida: Control = canvas_layer.get_child(0)
@onready var barra_progresso: ProgressBar = barra_vida.get_node("ProgressBar")


@export var distancia_curta := 150.0
@export var distancia_media := 350.0

@export var tempo_entre_ataques := 0.25
@export var tempo_cooldown_serie := 0.8
@export var duracao_dash := 0.35


@export var ataques_curta: Array[StringName] = [
	&"dash",
	&"dash",
	&"dash"
]

@export var ataques_media: Array[StringName] = [
	&"dash",
	&"dash"
]

@export var ataques_longa: Array[StringName] = [
	&"dash"
]


@export var porcentagem_fase_2 := 50.0

@export var delay_inicio := 1.5
@export var tempo_barra_vida := 0.45


@export var raio_bloqueio := 65.0
@export var tempo_bloqueio := 0.9
@export var knockback_bloqueio := 900.0


var vida_maxima := 0

var fase_2_iniciada := false
var ataque_em_serie := false
var movimentacao_travada := false
var bloqueando := false

var contador_knockback := 0


func _ready() -> void:
	super._ready()

	vida = 150
	vida_maxima = vida

	barra_vida.modulate.a = 0.0

	barra_progresso.max_value = vida_maxima
	barra_progresso.value = vida

	dano_processado.connect(atualizar_barra_vida)

	criar_linha_ioio()

	area_bloqueio.monitoring = false

	if not area_bloqueio.area_entered.is_connected(_on_bloqueio_area_entered):
		area_bloqueio.area_entered.connect(_on_bloqueio_area_entered)

	if not area_bloqueio.body_entered.is_connected(_on_bloqueio_body_entered):
		area_bloqueio.body_entered.connect(_on_bloqueio_body_entered)

	travar_movimentacao()
	iniciar_apresentacao_boss()


func criar_linha_ioio() -> void:
	linha_ioio = Line2D.new()
	linha_ioio.width = 6.0
	linha_ioio.antialiased = true
	linha_ioio.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha_ioio.end_cap_mode = Line2D.LINE_CAP_ROUND
	linha_ioio.joint_mode = Line2D.LINE_JOINT_ROUND
	linha_ioio.visible = false

	linha_ioio.add_point(Vector2.ZERO)
	linha_ioio.add_point(Vector2.ZERO)

	add_child(linha_ioio)


func _physics_process(delta: float) -> void:
	if fase_2_iniciada:
		velocity = Vector2.ZERO
		return

	atualizar_texto_distancia()
	atualizar_ray_los()

	if bloqueando:
		var speed_original := speed
		var max_speed_original := max_speed

		speed = 0.0
		max_speed = 0.0
		velocity = Vector2.ZERO

		super(delta)

		speed = speed_original
		max_speed = max_speed_original
		velocity = Vector2.ZERO

		return

	super(delta)


func atualizar_texto_distancia() -> void:
	if not is_instance_valid(alvo):
		texto_distancia2.text = "jogador invalido"
		return

	var distancia := global_position.distance_to(alvo.global_position)
	var estado_distancia := ""

	if distancia <= distancia_curta:
		estado_distancia = "curta"
	elif distancia <= distancia_media:
		estado_distancia = "media"
	else:
		estado_distancia = "longa"

	texto_distancia2.text = "distancia: %.1f\nestado: %s" % [
		distancia,
		estado_distancia
	]


func iniciar_fase_2() -> void:
	if fase_2_iniciada:
		return

	fase_2_iniciada = true

	ataque_em_serie = false
	bloqueando = false
	invulneravel = true

	atirar_tempo.stop()
	area_bloqueio.monitoring = false

	estado_ataque = ESTADOS_ATAQUE.IDEAL
	velocity = Vector2.ZERO

	parar_ataques()
	limpar_inimigos_invocados()

	travar_movimentacao()

	fase_2_iniciar.emit()


func parar_ataques() -> void:
	for ioio in ioios_ativos.duplicate():
		if is_instance_valid(ioio):
			ioio.queue_free()

	ioios_ativos.clear()

	linha_ioio.visible = false


func limpar_inimigos_invocados() -> void:
	for inimigo in inimigos_invocados.duplicate():
		if not is_instance_valid(inimigo):
			continue

		if inimigo.has_method("morrer"):
			inimigo.morrer()
		else:
			inimigo.queue_free()

	inimigos_invocados.clear()


func travar_movimentacao() -> void:
	movimentacao_travada = true
	velocity = Vector2.ZERO
	atirar_tempo.stop()

	set_physics_process(false)


func liberar_movimentacao() -> void:
	if fase_2_iniciada:
		return

	if not movimentacao_travada:
		return

	movimentacao_travada = false
	velocity = Vector2.ZERO

	set_physics_process(true)

	iniciar_timer_ataque()


func liberar_fase_2() -> void:
	if not fase_2_iniciada:
		return

	fase_2_iniciada = false
	invulneravel = false

	ataque_em_serie = false
	bloqueando = false

	movimentacao_travada = false

	velocity = Vector2.ZERO

	set_physics_process(true)

	iniciar_timer_ataque()


func iniciar_apresentacao_boss() -> void:
	await get_tree().create_timer(delay_inicio).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	await mostrar_barra_vida()

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	liberar_movimentacao()


func mostrar_barra_vida() -> void:
	barra_vida.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		barra_vida,
		"modulate:a",
		1.0,
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished


func atualizar_barra_vida() -> void:
	if vida_maxima <= 0:
		return

	barra_progresso.value = vida

	var porcentagem_vida := (
		float(vida) / float(vida_maxima)
	) * 100.0

	if porcentagem_vida <= porcentagem_fase_2:
		iniciar_fase_2()


func check_posicao_alvo() -> void:
	if fase_2_iniciada:
		return

	if ataque_em_serie or movimentacao_travada or bloqueando:
		return

	super.check_posicao_alvo()


func _on_atirar_tempo_timeout() -> void:
	if fase_2_iniciada:
		return

	if movimentacao_travada:
		return

	if ataque_em_serie:
		return

	if bloqueando:
		return

	if not esta_na_area:
		return

	if not is_instance_valid(alvo):
		return

	iniciar_serie_ataques()


func iniciar_timer_ataque() -> void:
	atirar_tempo.stop()

	if fase_2_iniciada:
		return

	if movimentacao_travada:
		return

	if ataque_em_serie:
		return

	if bloqueando:
		return

	if not esta_na_area:
		return

	atirar_tempo.start(tempo_cooldown_serie)


func iniciar_serie_ataques() -> void:
	if fase_2_iniciada:
		return

	if ataque_em_serie:
		return

	if movimentacao_travada:
		return

	if bloqueando:
		return

	ataque_em_serie = true
	atirar_tempo.stop()

	var serie := escolher_serie_ataques()

	for ataque in serie:
		if fase_2_iniciada:
			break

		if not is_inside_tree():
			break

		if not is_instance_valid(alvo):
			break

		if not esta_na_area:
			break

		await executar_ataque(ataque)

		if not is_inside_tree():
			return

		if fase_2_iniciada:
			break

		if not ataque_em_serie:
			return

		if not is_instance_valid(alvo):
			break

		if not esta_na_area:
			break

		if tempo_entre_ataques > 0.0:
			await get_tree().create_timer(tempo_entre_ataques).timeout

			if not is_inside_tree():
				return

			if fase_2_iniciada:
				break

			if not ataque_em_serie:
				return

	ataque_em_serie = false

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	if bloqueando:
		return

	estado_ataque = ESTADOS_ATAQUE.IDEAL
	velocity = Vector2.ZERO

	iniciar_timer_ataque()


func escolher_serie_ataques() -> Array[StringName]:
	if not is_instance_valid(alvo):
		return ataques_longa

	var distancia := global_position.distance_to(alvo.global_position)

	if distancia <= distancia_curta:
		return ataques_curta

	if distancia <= distancia_media:
		return ataques_media

	return ataques_longa



func criar_efeito_ataque() -> void:
	if efeito_ataque_cena == null:
		return

	var efeito = efeito_ataque_cena.instantiate()
	efeito.global_position = global_position

	get_tree().current_scene.add_child(efeito)

	modulate = Color(1.0, 0.527, 0.206, 1.0)

	await get_tree().create_timer(1.0).timeout

	modulate = Color.WHITE




func executar_ataque(nome: StringName) -> void:
	if fase_2_iniciada:
		return

	match nome:
		&"dash":
			dash()
			criar_efeito_ataque()

			await get_tree().create_timer(duracao_dash).timeout

			if not is_inside_tree():
				return

			if fase_2_iniciada:
				velocity = Vector2.ZERO
				return

			velocity = Vector2.ZERO
			estado_ataque = ESTADOS_ATAQUE.ATACANDO

		&"ataque_ioio":
			criar_efeito_ataque()

			await get_tree().create_timer(0.75).timeout

			if fase_2_iniciada:
				return

			await ataque_ioio()

		&"ataque_ioio_meia_lua":
			criar_efeito_ataque()

			await get_tree().create_timer(0.75).timeout

			if fase_2_iniciada:
				return

			await ataque_ioio_meia_lua()

		&"bloqueio":
			criar_efeito_ataque()

			await get_tree().create_timer(0.75).timeout

			if fase_2_iniciada:
				return

			await ataque_bloqueio()

		&"invocar_inimigos":
			criar_efeito_ataque()

			await get_tree().create_timer(0.75).timeout

			if fase_2_iniciada:
				return

			await invocar_inimigos()


func iniciar_dialogo(indice_inicial := 0) -> void:
	if dialogo == null:
		return

	dialogo_ocorrendo = true
	indice = indice_inicial

	travar_movimentacao()
	mostrar_fala()


func mostrar_fala() -> void:
	if not dialogo_ocorrendo:
		return

	if limite_dialogo != -1 and indice >= limite_dialogo:
		finalizar_dialogo()
		return

	if indice >= dialogo.falas.size():
		finalizar_dialogo()
		return

	var fala := dialogo.falas[indice]

	escrevendo = true
	pular_animacao = false

	texto_dialogo.text = fala.texto
	texto_dialogo.visible_characters = 0

	for i in fala.texto.length():
		if pular_animacao:
			break

		texto_dialogo.visible_characters = i + 1

		await get_tree().create_timer(fala.velocidade_texto).timeout

		if not is_inside_tree():
			return

	texto_dialogo.visible_characters = fala.texto.length()
	escrevendo = false


func finalizar_dialogo() -> void:
	if not dialogo_ocorrendo:
		return

	dialogo_ocorrendo = false
	escrevendo = false
	pular_animacao = false

	texto_dialogo.text = ""
	texto_dialogo.visible_characters = 0

	dialogo_finalizado.emit()

	if not ataque_em_serie and not fase_2_iniciada:
		liberar_movimentacao()


func _input(event: InputEvent) -> void:
	if not dialogo_ocorrendo:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			proxima_fala()


func proxima_fala() -> void:
	if not dialogo_ocorrendo:
		return

	if escrevendo:
		pular_animacao = true
		return

	indice += 1
	mostrar_fala()


func invocar_inimigos() -> void:
	if fase_2_iniciada:
		return

	var faltando := quantidade_max_invocados - inimigos_invocados.size()

	if faltando <= 0:
		return

	var quantidade = min(quantidade_invocada, faltando)

	if inimigos_invocados_cenas.is_empty():
		return

	estado_ataque = ESTADOS_ATAQUE.ATACANDO
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.25).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	for i in range(quantidade):
		if not is_inside_tree():
			return

		if fase_2_iniciada:
			return

		var cena_escolhida = inimigos_invocados_cenas.pick_random()

		if cena_escolhida == null:
			continue

		var angulo := (TAU / quantidade_invocada) * i
		var direcao := Vector2.RIGHT.rotated(angulo)

		var posicao_invocacao := global_position + (
			direcao * raio_invocacao
		)

		var explosao = efeito_ataque_cena.instantiate()
		explosao.global_position = posicao_invocacao
		explosao.z_index = 100
		get_tree().current_scene.add_child(explosao)

		var inimigo = cena_escolhida.instantiate()
		inimigo.ativo = true
		inimigo.global_position = posicao_invocacao
		get_tree().current_scene.add_child(inimigo)

		inimigos_invocados.append(inimigo)

		inimigo.tree_exited.connect(
			inimigo_invocado_morreu.bind(inimigo)
		)

		await get_tree().create_timer(0.08).timeout

		if fase_2_iniciada:
			return

	estado_ataque = ESTADOS_ATAQUE.ATACANDO


func inimigo_invocado_morreu(inimigo: Node) -> void:
	if inimigo in inimigos_invocados:
		inimigos_invocados.erase(inimigo)


func registrar_ioio(ioio: Node) -> void:
	ioios_ativos.append(ioio)

	ioio.tree_exited.connect(
		func():
			if ioio in ioios_ativos:
				ioios_ativos.erase(ioio)
	)


func ataque_ioio_meia_lua() -> void:
	if fase_2_iniciada:
		return

	if not is_instance_valid(alvo):
		return

	estado_ataque = ESTADOS_ATAQUE.ATACANDO

	await get_tree().create_timer(0.25).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	if not is_instance_valid(alvo):
		return

	var ioio = ioio_cena.instantiate()

	registrar_ioio(ioio)

	get_tree().current_scene.add_child(ioio)

	ioio.global_position = global_position

	ioio.iniciar_meia_lua(
		alvo,
		self
	)

	while is_instance_valid(ioio):
		if fase_2_iniciada:
			ioio.queue_free()
			break

		estado_ataque = ESTADOS_ATAQUE.ATACANDO
		atualizar_linha_ioio(ioio)

		await get_tree().process_frame

	linha_ioio.visible = false


func ataque_ioio() -> void:
	if fase_2_iniciada:
		return

	if not is_instance_valid(alvo):
		return

	estado_ataque = ESTADOS_ATAQUE.ATACANDO

	await get_tree().create_timer(0.25).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	if not is_instance_valid(alvo):
		return

	var ioio = ioio_cena.instantiate()

	registrar_ioio(ioio)

	ioio.global_position = global_position

	get_tree().current_scene.add_child(ioio)

	ioio.iniciar(
		alvo,
		self,
		distancia_media * 2
	)

	while is_instance_valid(ioio):
		if fase_2_iniciada:
			ioio.queue_free()
			break

		estado_ataque = ESTADOS_ATAQUE.ATACANDO
		atualizar_linha_ioio(ioio)

		await get_tree().process_frame

	linha_ioio.visible = false


func ataque_bloqueio() -> void:
	if fase_2_iniciada:
		return

	if bloqueando:
		return

	if not is_inside_tree():
		return

	bloqueando = true
	invulneravel = true
	estado_ataque = ESTADOS_ATAQUE.PARRY

	atirar_tempo.stop()

	await get_tree().create_timer(0.1).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		bloqueando = false
		invulneravel = true
		return

	var ioio = ioio_cena.instantiate()

	registrar_ioio(ioio)

	ioio.global_position = global_position

	get_tree().current_scene.add_child(ioio)

	ioio.iniciar_bloqueio(
		self,
		raio_bloqueio,
		tempo_bloqueio
	)

	while is_instance_valid(ioio):
		if fase_2_iniciada:
			ioio.queue_free()
			break

		if not bloqueando:
			break

		estado_ataque = ESTADOS_ATAQUE.PARRY
		atualizar_linha_ioio(ioio)

		await get_tree().process_frame

	linha_ioio.visible = false

	bloqueando = false

	if fase_2_iniciada:
		invulneravel = true
		return

	invulneravel = false
	estado_ataque = ESTADOS_ATAQUE.IDEAL
	velocity = Vector2.ZERO

	iniciar_timer_ataque()


func atualizar_linha_ioio(ioio: Node2D) -> void:
	if not is_instance_valid(ioio):
		linha_ioio.visible = false
		return

	linha_ioio.visible = true

	var inicio := Vector2.ZERO
	var fim := to_local(ioio.global_position)

	var meio := (inicio + fim) / 2.0
	var direcao_linha := inicio.direction_to(fim)

	var perpendicular := Vector2(
		-direcao_linha.y,
		direcao_linha.x
	)

	var controle := meio + perpendicular * 25.0

	for i in linha_ioio.get_point_count():
		var t := float(i) / float(
			linha_ioio.get_point_count() - 1
		)

		var ponto_a := inicio.lerp(controle, t)
		var ponto_b := controle.lerp(fim, t)
		var ponto := ponto_a.lerp(ponto_b, t)

		linha_ioio.set_point_position(i, ponto)


func atualizar_ray_los() -> void:
	if not is_instance_valid(alvo):
		ray_los.target_position = Vector2.ZERO
		return

	var posicao_alvo = ray_los.to_local(
		alvo.global_position
	)

	ray_los.target_position = posicao_alvo
	ray_los.force_raycast_update()


func _on_circulo_de_visao_body_entered(body: Node2D) -> void:
	if fase_2_iniciada:
		return

	if not body.is_in_group("jogador"):
		return

	esta_na_area = true

	if movimentacao_travada:
		return

	if ataque_em_serie:
		return

	if bloqueando:
		return

	iniciar_timer_ataque()


func _on_circulo_de_visao_body_exited(body: Node2D) -> void:
	if fase_2_iniciada:
		return

	if not body.is_in_group("jogador"):
		return

	esta_na_area = false
	atirar_tempo.stop()

	if ataque_em_serie:
		return

	if bloqueando:
		return

	estado_ataque = ESTADOS_ATAQUE.APROXIMAR
	velocity = Vector2.ZERO


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if fase_2_iniciada:
		return

	if not body.is_in_group("jogador"):
		return

	esta_na_area_hurtbox = true

	if body.invencivel:
		return

	if estado_ataque == ESTADOS_ATAQUE.IDEAL:
		body.perder_vida(
			1,
			LOS.target_position.normalized(),
			knockback_normal
		)

	if estado_ataque == ESTADOS_ATAQUE.DASH:
		body.perder_vida(
			1,
			LOS.target_position.normalized(),
			knockback_dash
		)

		estado_ataque = ESTADOS_ATAQUE.ATACANDO
		velocity = Vector2.ZERO


func _on_hurtbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		esta_na_area_hurtbox = false


func _on_bloqueio_area_entered(area: Area2D) -> void:
	if not bloqueando:
		return

	if area.is_in_group("arma_multimidia"):
		parry_arma(area)
		return

	if area.has_method("refletir"):
		refletir_projetil(area)


func _on_bloqueio_body_entered(body: Node2D) -> void:
	if not bloqueando:
		return

	if body.is_in_group("arma_multimidia"):
		parry_arma(body)
		return

	if body.has_method("refletir"):
		refletir_projetil(body)


func parry_arma(arma: Node2D) -> void:
	var jogador := encontrar_jogador(arma)

	if jogador == null:
		return

	if not jogador.has_method("perder_vida"):
		return

	if jogador.invencivel:
		return

	var direcao_knockback := global_position.direction_to(
		jogador.global_position
	)

	jogador.perder_vida(
		0,
		direcao_knockback,
		knockback_bloqueio
	)


func refletir_projetil(projetil: Node2D) -> void:
	if not projetil.has_method("refletir"):
		return

	var direcao_refletida := global_position.direction_to(
		projetil.global_position
	)

	projetil.refletir(direcao_refletida)


func encontrar_jogador(no: Node) -> Node2D:
	var atual: Node = no

	while atual != null:
		if atual.is_in_group("jogador"):
			return atual

		atual = atual.get_parent()

	return null


func receber_dano(dano: int) -> void:
	if invulneravel:
		return

	if escudo <= 0:
		vida -= dano
	else:
		escudo -= dano

	if vida <= 0:
		limpar_inimigos_invocados()
		parar_ataques()

		var particula_morte = particula_morte_cena.instantiate()
		particula_morte.position = global_position
		get_tree().current_scene.add_child(particula_morte)

		queue_free()
		return

	dano_processado.emit()


func aplicar_knockback(direcao: Vector2, forca: float) -> void:
	if invulneravel:
		return

	contador_knockback += 1

	var meu_contador := contador_knockback

	estado_atual = ESTADOS.HIT
	knockback_force = direcao.normalized() * forca

	sprite.modulate = Color(10, 10, 10)

	await get_tree().create_timer(0.15).timeout

	if not is_inside_tree():
		return

	if fase_2_iniciada:
		return

	if meu_contador != contador_knockback:
		return

	estado_atual = ESTADOS.CACANDO
	sprite.modulate = Color.WHITE
