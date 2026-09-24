extends Control

var CAMINHO_TUTORIAL := "res://cenas_tscn/fases/tutorial.tscn"


@onready var mira = $mira
@onready var jogador = $jogador
@onready var fullstack = $fullstack

@onready var botoes = $HBoxContainer
@onready var botao_atacar = $HBoxContainer/atacar
@onready var botao_item = $HBoxContainer/item
@onready var botao_acao = $HBoxContainer/acao
@onready var botao_fugir = $HBoxContainer/fugir
@onready var texto_da_acao = $HBoxContainer/texto_da_acao

@onready var status_jogador = $status_jogador
@onready var progressbarhp_jogador = $status_jogador/VBoxContainer/hp/ProgressBarHP
@onready var nome_personagem_hp = $status_jogador/VBoxContainer/hp/nome_hp
@onready var nome_personagem = $status_jogador/VBoxContainer/nome
@onready var lvl = $status_jogador/VBoxContainer/lvl

@onready var status_fullstack = $status_fullstack
@onready var progressbarhp_fullstack = $status_fullstack/VBoxContainer/hp/ProgressBarHP
@onready var nome_fullstack_hp = $status_fullstack/VBoxContainer/hp/nome_hp
@onready var nome_fullstack = $status_fullstack/VBoxContainer/nome

@onready var grid_acao = $HBoxContainer/GridAcao
@onready var acao1 = $HBoxContainer/GridAcao/acao1
@onready var acao2 = $HBoxContainer/GridAcao/acao2
@onready var acao3 = $HBoxContainer/GridAcao/acao3
@onready var acao4 = $HBoxContainer/GridAcao/acao4


## sprites e valores basicos

var SPRITE_PROGRAMADOR = preload("res://tres/spriteframes/minigame_fullstack/prog.tres")
var SPRITE_MULTIMIDIA = preload("res://tres/spriteframes/minigame_fullstack/mult.tres")

var VIDA_PROGRAMADOR := 100
var VIDA_MULTIMIDIA := 100
var VIDA_FULLSTACK := 100

var VELOCIDADE_PROGRAMADOR := 100
var VELOCIDADE_MULTIMIDIA := 100
var VELOCIDADE_FULLSTACK := 80


## estados da batalha

enum ESTADOS {
	ENTRADA,	
	ESCOLHENDO,
	EXECUTANDO,
	VITORIA,
	DERROTA
}


enum SUBMENUS {
	NENHUM,
	GOLPES,
	ACOES
}


## estado atual da batalha

var estado_atual: ESTADOS = ESTADOS.ENTRADA
var submenu_atual: SUBMENUS = SUBMENUS.NENHUM

var batalha_finalizando := false
var pular_animacao := false
var primeiro_turno_fullstack := true


## informacoes dos personagens

var nome_jogador := ""
var nome_inimigo := "fullstack"

var vida_jogador := 100
var vida_fullstack_atual := 1

var vida_maxima_jogador := 100
var vida_maxima_fullstack := VIDA_FULLSTACK

var velocidade_jogador := 100
var velocidade_fullstack := VELOCIDADE_FULLSTACK


## efeitos da batalha

var protegendo_jogador := false
var protegendo_fullstack := false

var bonus_dano_jogador := 0
var bonus_dano_fullstack := 0


## golpes e acoes

var golpes_jogador: Array[Dictionary] = []
var acoes_jogador: Array[Dictionary] = []

var botoes_grid = []


## sistema de texto

var escrevendo_texto := false
var aguardando_texto := false
var texto_id := 0

@export var velocidade_texto := 0.03


## controle

var indice_controle := 0
var controle_eixo_travado := false
var tempo_controle := 0.0


## niveis

@export_category("Niveis")
@export var nivel_programador := 1
@export var nivel_multimidia := 1


## golpes do programador

@export_category("Golpes do programador")
@export var golpes: Array[Dictionary] = [
	{"nome": "tiro com a arma", "dano": 40},
	{"nome": "programar na godot", "dano": 40},
	{"nome": "passinho do sabor", "dano": 40},
]


## acoes do programador

@export_category("Acoes do programador")
@export var acoes: Array[Dictionary] = [
	{"nome": "analisar teste", "tipo": "analisar"},
	{"nome": "proteger teste", "tipo": "proteger"},
	{"nome": "cura teste", "tipo": "curar", "valor": 15},
	{"nome": "buff plus teste", "tipo": "buff plus", "valor": 5}
]


## golpes e acoes da multimidia

@export_category("Golpes da multimidia")
@export var golpes_multimidia: Array[Dictionary] = [
	{"nome": "spritesheet com proporção errada", "dano": 40},
	{"nome": "rajada de krita", "dano": 15},
	{"nome": "desenho a mão", "dano": 20},
	{"nome": "machadada", "dano": 60},
]


@export_category("Acoes da multimidia")
@export var acoes_multimidia: Array[Dictionary] = [
	{"nome": "analisar teste", "tipo": "analisar"},
	{"nome": "proteger teste", "tipo": "proteger"},
	{"nome": "cura teste", "tipo": "curar", "valor": 15},
	{"nome": "buff plus teste", "tipo": "buff plus", "valor": 5}
]


## golpes do fullstack

@export_category("Golpes do fullstack")
@export var golpes_fullstack: Array[Dictionary] = [
	{"nome": "blender pra programar", "dano": 18},
	{"nome": "modelos 3d", "dano": 18},
	{"nome": "programar na godot", "dano": 18},
	{"nome": "rajada de krita", "dano": 18},
]


## acoes do fullstack

@export_category("Acoes do fullstack")
@export var acoes_fullstack: Array[Dictionary] = [
	{"nome": "cura teste", "tipo": "curar", "valor": 12},
	{"nome": "buff teste", "tipo": "buff", "valor": 8},
	{"nome": "proteger teste", "tipo": "proteger"},
	{"nome": "analisar teste", "tipo": "analisar"}
]


## comeca tudo aqui

func _ready() -> void:
	await get_tree().process_frame

	if Global.arma_atual == 1:
		nome_jogador = "multimidia"
		jogador.sprite_frames = SPRITE_MULTIMIDIA
		vida_jogador = VIDA_MULTIMIDIA
		vida_maxima_jogador = VIDA_MULTIMIDIA
		velocidade_jogador = VELOCIDADE_MULTIMIDIA
		golpes_jogador = golpes_multimidia
		acoes_jogador = acoes_multimidia
		lvl.text = "Lv. " + str(nivel_multimidia)
	else:
		nome_jogador = "programador"
		jogador.sprite_frames = SPRITE_PROGRAMADOR
		vida_jogador = VIDA_PROGRAMADOR
		vida_maxima_jogador = VIDA_PROGRAMADOR
		velocidade_jogador = VELOCIDADE_PROGRAMADOR
		golpes_jogador = golpes
		acoes_jogador = acoes
		lvl.text = "Lv. " + str(nivel_programador)

	nome_personagem.text = nome_jogador
	nome_personagem_hp.text = nome_jogador
	nome_fullstack.text = nome_inimigo
	nome_fullstack_hp.text = nome_inimigo

	progressbarhp_jogador.max_value = vida_maxima_jogador
	progressbarhp_jogador.value = vida_jogador
	progressbarhp_fullstack.max_value = vida_maxima_fullstack
	progressbarhp_fullstack.value = vida_fullstack_atual

	botoes_grid = [acao1, acao2, acao3, acao4]

	grid_acao.columns = 2
	grid_acao.visible = false

	for botao in botoes_grid:
		botao.visible = false
		botao.disabled = true
		botao.focus_mode = Control.FOCUS_ALL
		botao.pressed.connect(_selecionar_slot.bind(botao))

	for botao in [botao_atacar, botao_item, botao_acao, botao_fugir]:
		botao.focus_mode = Control.FOCUS_ALL

	botoes.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await fazer_entrada()
	await iniciar_batalha()


## entrada dos personagens
func fazer_entrada() -> void:
	var tela := get_viewport_rect().size

	var pos_jogador = jogador.position
	var pos_fullstack = fullstack.position
	var pos_botoes = botoes.position
	var pos_status_jogador = status_jogador.position
	var pos_status_fullstack = status_fullstack.position

	var escala_jogador = jogador.scale
	var escala_fullstack = fullstack.scale
	var escala_status_jogador = status_jogador.scale
	var escala_status_fullstack = status_fullstack.scale

	jogador.position = pos_jogador + Vector2(-tela.x - 300, 0)
	fullstack.position = pos_fullstack + Vector2(tela.x + 300, 0)

	status_jogador.position = pos_status_jogador + Vector2(-tela.x - 300, 0)
	status_fullstack.position = pos_status_fullstack + Vector2(tela.x + 300, 0)

	botoes.position = pos_botoes + Vector2(0, -tela.y - 250)

	jogador.scale = escala_jogador * 0.92
	fullstack.scale = escala_fullstack * 0.92
	status_jogador.scale = escala_status_jogador * 0.92
	status_fullstack.scale = escala_status_fullstack * 0.92
	botoes.modulate.a = 0.0

	await get_tree().create_timer(0.8).timeout

	var tween := create_tween()

	tween.tween_property(jogador, "position", pos_jogador + Vector2(22, 0), 0.65).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(jogador, "scale", escala_jogador * 1.03, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_jogador, "position", pos_status_jogador + Vector2(22, 0), 0.65).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_jogador, "scale", escala_status_jogador * 1.03, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(jogador, "position", pos_jogador, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(jogador, "scale", escala_jogador, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_jogador, "position", pos_status_jogador, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_jogador, "scale", escala_status_jogador, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween = create_tween()

	tween.tween_interval(0.08)
	tween.tween_property(fullstack, "position", pos_fullstack + Vector2(-22, 0), 0.65).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fullstack, "scale", escala_fullstack * 1.03, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_fullstack, "position", pos_status_fullstack + Vector2(-22, 0), 0.65).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_fullstack, "scale", escala_status_fullstack * 1.03, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(fullstack, "position", pos_fullstack, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fullstack, "scale", escala_fullstack, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_fullstack, "position", pos_status_fullstack, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(status_fullstack, "scale", escala_status_fullstack, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.45).timeout

	tween = create_tween()

	tween.tween_property(botoes, "position", pos_botoes + Vector2(0, 12), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(botoes, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

	tween = create_tween()

	tween.tween_property(botoes, "position", pos_botoes, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## agora libera a batalha

func iniciar_batalha() -> void:
	estado_atual = ESTADOS.ESCOLHENDO
	mostrar_menu_principal()
	await mostrar_texto("o que voce vai fazer?", false)


#pra nao bugar quando ta escrevendo texto e vc escolhe msm assim
func pode_escolher() -> bool:
	return estado_atual == ESTADOS.ESCOLHENDO and not escrevendo_texto


## texto

func mostrar_texto(texto: String, esperar_continuacao := true) -> void:
	texto_id += 1
	var id := texto_id

	escrevendo_texto = true
	aguardando_texto = false
	pular_animacao = false
	texto_da_acao.text = texto
	texto_da_acao.visible_characters = 0

	for i in range(texto.length()):
		if id != texto_id:
			return

		if pular_animacao:
			break

		texto_da_acao.visible_characters = i + 1
		await get_tree().create_timer(velocidade_texto).timeout

	if id != texto_id:
		return

	texto_da_acao.visible_characters = texto.length()
	escrevendo_texto = false

	if not esperar_continuacao:
		return

	aguardando_texto = true

	while aguardando_texto and id == texto_id:
		await get_tree().process_frame


## menus

func esconder_menu_principal() -> void:
	for botao in [botao_atacar, botao_item, botao_acao, botao_fugir]:
		botao.visible = false


func mostrar_menu_principal() -> void:
	submenu_atual = SUBMENUS.NENHUM
	grid_acao.visible = false

	for botao in botoes_grid:
		botao.visible = false
		botao.disabled = true

	for botao in [botao_atacar, botao_item, botao_acao, botao_fugir]:
		botao.visible = true

	liberar_botoes()

	if Global.usando_controle:
		await get_tree().process_frame
		focar_menu_principal()


func mostrar_submenu(tipo: SUBMENUS) -> void:
	submenu_atual = tipo
	esconder_menu_principal()
	grid_acao.visible = true

	var lista := golpes_jogador

	if tipo == SUBMENUS.ACOES:
		lista = acoes_jogador

	for i in range(botoes_grid.size()):
		var botao = botoes_grid[i]

		botao.visible = i < lista.size()
		botao.disabled = i >= lista.size()

		if i < lista.size():
			botao.text = lista[i]["nome"]

	if Global.usando_controle:
		await get_tree().process_frame
		focar_submenu()


func voltar_menu_principal() -> void:
	if not pode_escolher():
		return

	mostrar_menu_principal()
	await mostrar_texto("o que voce vai fazer?", false)


## botoes

func travar_botoes() -> void:
	for botao in [botao_atacar, botao_item, botao_acao, botao_fugir]:
		botao.disabled = true

	for botao in botoes_grid:
		botao.disabled = true


func liberar_botoes() -> void:
	for botao in [botao_atacar, botao_item, botao_acao, botao_fugir]:
		botao.disabled = false

	for botao in botoes_grid:
		if botao.visible:
			botao.disabled = false


func focar_menu_principal() -> void:
	if Global.usando_controle:
		indice_controle = 0
		botao_atacar.grab_focus()


func focar_submenu() -> void:
	if not Global.usando_controle:
		return

	indice_controle = 0

	for botao in botoes_grid:
		if botao.visible and not botao.disabled:
			botao.grab_focus()
			return


## botoes principais

func _on_atacar_button_down() -> void:
	if pode_escolher():
		mostrar_submenu(SUBMENUS.GOLPES)


func _on_item_button_down() -> void:
	if not pode_escolher():
		return

	travar_botoes()
	await mostrar_texto("seu inventario esta vazio. igual sua esperanca.")

	if estado_atual == ESTADOS.ESCOLHENDO:
		mostrar_menu_principal()
		await mostrar_texto("o que voce vai fazer?", false)
		liberar_botoes()


func _on_acao_button_down() -> void:
	if pode_escolher():
		mostrar_submenu(SUBMENUS.ACOES)


func _on_fugir_button_down() -> void:
	if not pode_escolher():
		return

	travar_botoes()
	await mostrar_texto("fugir? kkkkk. voce nao pode sair daqui nao pae.")

	if estado_atual == ESTADOS.ESCOLHENDO:
		mostrar_menu_principal()
		await mostrar_texto("o que voce vai fazer?", false)
		liberar_botoes()


## aqui eu escolho o que o fullstack vai fazer

func escolher_acao_inimigo() -> Dictionary:
	if primeiro_turno_fullstack:
		return {
			"quem": "inimigo",
			"tipo": "acao",
			"nome": "primeiro turno",
			"acao": "cura_primeiro_turno",
			"valor": 0
		}

	if randi_range(0, 99) < 70:
		var golpe = golpes_fullstack.pick_random()

		return {
			"quem": "inimigo",
			"tipo": "atacar",
			"nome": golpe["nome"],
			"dano": golpe["dano"]
		}

	var acao = acoes_fullstack.pick_random()

	return {
		"quem": "inimigo",
		"tipo": "acao",
		"nome": acao["nome"],
		"acao": acao["tipo"],
		"valor": acao.get("valor", 0)
	}


## turno

func preparar_turno(acao_jogador: Dictionary) -> void:
	var inimigo := escolher_acao_inimigo()
	var turno: Array = []

	if velocidade_jogador >= velocidade_fullstack:
		turno = [acao_jogador, inimigo]
	else:
		turno = [inimigo, acao_jogador]

	await executar_turno(turno)


func _selecionar_slot(botao) -> void:
	if not pode_escolher():
		return

	var indice := botoes_grid.find(botao)

	if indice == -1:
		return

	if submenu_atual == SUBMENUS.GOLPES:
		if indice >= golpes_jogador.size():
			return

		var golpe = golpes_jogador[indice]

		travar_botoes()

		await preparar_turno({
			"quem": "jogador",
			"tipo": "atacar",
			"nome": golpe["nome"],
			"dano": golpe["dano"]
		})

	elif submenu_atual == SUBMENUS.ACOES:
		if indice >= acoes_jogador.size():
			return

		var acao = acoes_jogador[indice]

		travar_botoes()

		await preparar_turno({
			"quem": "jogador",
			"tipo": "acao",
			"nome": acao["nome"],
			"acao": acao["tipo"],
			"valor": acao.get("valor", 0)
		})


## aqui acontece o turno em si

func executar_turno(turno: Array) -> void:
	estado_atual = ESTADOS.EXECUTANDO
	esconder_menu_principal()
	grid_acao.visible = false

	for acao in turno:
		if vida_jogador <= 0:
			break

		if vida_fullstack_atual <= 0 and not primeiro_turno_fullstack:
			break

		await executar_acao(acao)

	await verificar_fim_batalha()

	if estado_atual == ESTADOS.EXECUTANDO:
		estado_atual = ESTADOS.ESCOLHENDO
		mostrar_menu_principal()
		await mostrar_texto("o que voce vai fazer?", false)
		liberar_botoes()


func executar_acao(acao: Dictionary) -> void:
	if acao["tipo"] == "atacar":
		if acao["quem"] == "jogador":
			await ataque_jogador(acao)
		else:
			await ataque_fullstack(acao)

	elif acao["tipo"] == "acao":
		if acao["quem"] == "jogador":
			await executar_acao_jogador(acao)
		else:
			await executar_acao_fullstack(acao)


## ataques

func ataque_jogador(golpe: Dictionary) -> void:
	await mostrar_texto(nome_jogador + " usou " + golpe["nome"] + "!")

	var original = jogador.position
	var tween := create_tween()

	tween.tween_property(
		jogador,
		"position",
		original + Vector2(35, 0),
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		jogador,
		"position",
		original,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	var dano := int(golpe["dano"]) + bonus_dano_jogador
	bonus_dano_jogador = 0

	if protegendo_fullstack:
		dano = max(int(dano * 0.5), 1)

		await mostrar_texto("o inimigo bloqueou parte do golpe!")
		protegendo_fullstack = false

	vida_fullstack_atual -= dano

	if primeiro_turno_fullstack:
		vida_fullstack_atual = max(vida_fullstack_atual, 1)
	else:
		vida_fullstack_atual = max(vida_fullstack_atual, 0)

	progressbarhp_fullstack.value = vida_fullstack_atual
	await get_tree().create_timer(0.35).timeout


func ataque_fullstack(golpe: Dictionary) -> void:
	await mostrar_texto(nome_inimigo + " usou " + golpe["nome"] + "!")

	var original = fullstack.position
	var tween := create_tween()

	tween.tween_property(
		fullstack,
		"position",
		original + Vector2(-35, 0),
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		fullstack,
		"position",
		original,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	var dano := int(golpe["dano"]) + bonus_dano_fullstack
	bonus_dano_fullstack = 0

	if protegendo_jogador:
		dano = max(int(dano * 0.5), 1)

		await mostrar_texto("voce bloqueou parte do golpe!")
		protegendo_jogador = false

	vida_jogador = max(vida_jogador - dano, 0)
	progressbarhp_jogador.value = vida_jogador

	await get_tree().create_timer(0.35).timeout


## acoes dos personagens

func executar_acao_jogador(acao: Dictionary) -> void:
	var tipo = acao["acao"]

	if tipo == "analisar":
		await mostrar_texto(nome_jogador + " analisou o inimigo.")

	elif tipo == "proteger":
		protegendo_jogador = true
		await mostrar_texto(nome_jogador + " se preparou para o proximo ataque!")

	elif tipo == "curar":
		var cura = acao["valor"]

		vida_jogador = min(
			vida_jogador + cura,
			vida_maxima_jogador
		)

		progressbarhp_jogador.value = vida_jogador

		await mostrar_texto(
			nome_jogador + " recuperou " + str(cura) + " hp!"
		)

	elif tipo == "buff plus":
		var cura = acao["valor"]

		bonus_dano_jogador += 5
		progressbarhp_jogador.value = vida_jogador

		await mostrar_texto(
			nome_jogador + " resenhou legal agora. +" + "+5 de dano!"
		)

	elif tipo == "buff":
		var bonus = acao["valor"]

		bonus_dano_jogador += bonus

		await mostrar_texto(
			nome_jogador + " se buffou. proximo golpe +" + str(bonus) + " de dano!"
		)


func executar_acao_fullstack(acao: Dictionary) -> void:
	var tipo = acao["acao"]

	if tipo == "cura_primeiro_turno":
		vida_fullstack_atual = vida_maxima_fullstack
		progressbarhp_fullstack.value = vida_fullstack_atual

		primeiro_turno_fullstack = false

		await mostrar_texto("o fullstack só negou receber teu ataque kkkkk")
		await mostrar_texto("fullstack recupera toda a vida")

	elif tipo == "analisar":
		await mostrar_texto(nome_inimigo + " analisou voce.")

	elif tipo == "proteger":
		protegendo_fullstack = true

		await mostrar_texto(
			nome_inimigo + " ativou uma protecao!"
		)

	elif tipo == "curar":
		var cura = acao["valor"]

		vida_fullstack_atual = min(
			vida_fullstack_atual + cura,
			vida_maxima_fullstack
		)

		progressbarhp_fullstack.value = vida_fullstack_atual

		await mostrar_texto(
			nome_inimigo + " recuperou " + str(cura) + " hp!"
		)

	elif tipo == "buff plus":
		var cura = acao["valor"]

		vida_fullstack_atual = min(
			vida_fullstack_atual + cura,
			vida_maxima_fullstack
		)

		bonus_dano_fullstack += 5
		progressbarhp_fullstack.value = vida_fullstack_atual

		await mostrar_texto(
			nome_inimigo + " resenhou legal agora. +" + str(cura) + " hp e +5 de dano!"
		)

	elif tipo == "buff":
		var bonus = acao["valor"]

		bonus_dano_fullstack += bonus

		await mostrar_texto(
			nome_inimigo + " se buffou. proximo golpe +" + str(bonus) + " de dano!"
		)


## fim da batalha

func verificar_fim_batalha() -> void:
	if vida_fullstack_atual <= 0:
		await vencer_batalha()
	elif vida_jogador <= 0:
		await perder_batalha()


func vencer_batalha() -> void:
	if batalha_finalizando:
		return

	batalha_finalizando = true
	estado_atual = ESTADOS.VITORIA
	travar_botoes()

	await mostrar_texto("fullstack foi derrotado!", false)
	await get_tree().create_timer(1).timeout

	await TransicaoMinigame.fechar_minigame()


func perder_batalha() -> void:
	estado_atual = ESTADOS.DERROTA
	travar_botoes()

	await mostrar_texto("fullstack ganhou de voce. skill issue.")


## aqui eu controlo o controle

func _input(event: InputEvent) -> void:
	## se apertou qualquer coisa no controle, eu considero que esta usando controle
	if event is InputEventJoypadButton:
		Global.usando_controle = true

		if event.button_index == JOY_BUTTON_A and event.pressed:
			if escrevendo_texto:
				pular_animacao = true
			elif aguardando_texto:
				aguardando_texto = false
			elif estado_atual == ESTADOS.ESCOLHENDO:
				selecionar_com_controle()

			get_viewport().set_input_as_handled()
			return

		if event.button_index == JOY_BUTTON_B and event.pressed:
			if estado_atual == ESTADOS.ESCOLHENDO and submenu_atual != SUBMENUS.NENHUM:
				voltar_menu_principal()

				get_viewport().set_input_as_handled()

			return

		var direcao := Vector2i.ZERO

		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				direcao = Vector2i(0, -1)

			JOY_BUTTON_DPAD_DOWN:
				direcao = Vector2i(0, 1)

			JOY_BUTTON_DPAD_LEFT:
				direcao = Vector2i(-1, 0)

			JOY_BUTTON_DPAD_RIGHT:
				direcao = Vector2i(1, 0)

		if direcao != Vector2i.ZERO and event.pressed:
			navegar_controle(direcao)

			get_viewport().set_input_as_handled()
			return


	## analogico

	if event is InputEventJoypadMotion:
		Global.usando_controle = true

		if event.axis != JOY_AXIS_LEFT_X and event.axis != JOY_AXIS_LEFT_Y:
			return

		if abs(event.axis_value) < 0.4:
			controle_eixo_travado = false
			return

		if controle_eixo_travado:
			return

		controle_eixo_travado = true

		if event.axis == JOY_AXIS_LEFT_X:
			navegar_controle(
				Vector2i(
					1 if event.axis_value > 0 else -1,
					0
				)
			)
		else:
			navegar_controle(
				Vector2i(
					0,
					1 if event.axis_value > 0 else -1
				)
			)

		get_viewport().set_input_as_handled()
		return


	## teclado e mouse fazem a mira aparecer de novo

	if event is InputEventKey and event.pressed:
		Global.usando_controle = false

	if event is InputEventMouseMotion:
		Global.usando_controle = false

	if event is InputEventMouseButton and event.pressed:
		Global.usando_controle = false

		if event.button_index == MOUSE_BUTTON_LEFT:
			if escrevendo_texto:
				pular_animacao = true
				get_viewport().set_input_as_handled()
				return

			if aguardando_texto:
				aguardando_texto = false
				get_viewport().set_input_as_handled()
				return


	## teclado para texto

	if event.is_action_pressed("ui_accept") \
	or event.is_action_pressed("ui_select") \
	or event.is_action_pressed("pular_dialogo"):

		if escrevendo_texto:
			pular_animacao = true
			get_viewport().set_input_as_handled()
			return

		if aguardando_texto:
			aguardando_texto = false
			get_viewport().set_input_as_handled()
			return


	## teclado para voltar

	if event.is_action_pressed("ui_cancel"):
		if estado_atual == ESTADOS.ESCOLHENDO and submenu_atual != SUBMENUS.NENHUM:
			voltar_menu_principal()
			get_viewport().set_input_as_handled()


## navegacao do controle

func navegar_controle(direcao: Vector2i) -> void:
	if not pode_escolher() or aguardando_texto or tempo_controle > 0:
		return

	tempo_controle = 0.2

	if submenu_atual == SUBMENUS.NENHUM:
		indice_controle += direcao.x + direcao.y
		indice_controle = clamp(indice_controle, 0, 3)

		var botoes_principais := [
			botao_atacar,
			botao_item,
			botao_acao,
			botao_fugir
		]

		if botoes_principais[indice_controle].visible \
		and not botoes_principais[indice_controle].disabled:
			botoes_principais[indice_controle].grab_focus()

		return


	var ativos: Array = []

	for botao in botoes_grid:
		if botao.visible and not botao.disabled:
			ativos.append(botao)

	if ativos.is_empty():
		return

	if direcao.x > 0 and indice_controle % 2 == 0:
		indice_controle += 1

	elif direcao.x < 0 and indice_controle % 2 == 1:
		indice_controle -= 1

	elif direcao.y > 0 and indice_controle < 2 and ativos.size() > indice_controle + 2:
		indice_controle += 2

	elif direcao.y < 0 and indice_controle >= 2:
		indice_controle -= 2

	indice_controle = clamp(
		indice_controle,
		0,
		ativos.size() - 1
	)

	ativos[indice_controle].grab_focus()


## selecionar com controle

func selecionar_com_controle() -> void:
	if not pode_escolher():
		return

	if aguardando_texto:
		aguardando_texto = false
		return

	if submenu_atual == SUBMENUS.NENHUM:
		var botoes_principais := [
			botao_atacar,
			botao_item,
			botao_acao,
			botao_fugir
		]

		var botao = botoes_principais[
			clamp(indice_controle, 0, 3)
		]

		if botao.disabled or not botao.visible:
			return

		match indice_controle:
			0:
				_on_atacar_button_down()

			1:
				_on_item_button_down()

			2:
				_on_acao_button_down()

			3:
				_on_fugir_button_down()

		return


	var ativos: Array = []

	for botao in botoes_grid:
		if botao.visible and not botao.disabled:
			ativos.append(botao)

	if ativos.is_empty():
		return

	indice_controle = clamp(
		indice_controle,
		0,
		ativos.size() - 1
	)

	_selecionar_slot(ativos[indice_controle])


## aqui eu so controlo o cursor e o tempo do controle

func atualizar_cursor() -> void:
	if mira:
		mira.visible = not Global.usando_controle


func _process(delta: float) -> void:
	atualizar_cursor()

	if tempo_controle > 0:
		tempo_controle -= delta
