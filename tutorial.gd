extends Node2D
var boss: Node2D
const CAMINHO_MINIGAME := "res://cenas_tscn/inimigos_tscn/boss_tscn/fullstack_tscn/minigame_fullstack_rpg_cena.tscn"
var CENA_CAIXA: PackedScene = preload("res://cenas_tscn/caixa.tscn")
var cena_boss:= preload("res://cenas_tscn/inimigos_tscn/boss_tscn/fullstack_tscn/boss_fullstack.tscn")

@onready var npc_fullstack_cena = preload("res://cenas_tscn/inimigos_tscn/boss_tscn/fullstack_tscn/npc_fullstack.tscn")

enum FASE_SALA_1 {
	INICIO,
	TUTORIAL_INICIAL,
	CAIXAS_1,
	CAIXAS_2,
	PREPARANDO_DUMMY,
	DUMMY,
	FINALIZANDO,
	FINALIZADA
}


@export var personagem: CharacterBody2D

var camera: Camera2D
@onready var npc = get_node("NPC Fullstack")
@onready var dummy = get_node("Dummy")
@onready var dummy_4 = get_node("Dummy4")
@onready var bebedouros = get_tree().get_nodes_in_group("bebedouro")

@onready var spawn_caixa_1 = get_node("caixas_spanwpoints/caixa_1")
@onready var spawn_caixa_2 = get_node("caixas_spanwpoints/caixa_2")

@onready var posicao_final_1 = get_node("posicoes/final_1")
@onready var posicao_inicial_2 = get_node("posicoes/inicial_2")
@onready var posicao_final_2 = get_node("posicoes/final_2")

@onready var porta_2 = get_node("parede/porta_2")


var fase_sala_1: FASE_SALA_1 = FASE_SALA_1.INICIO

var tutorial_sala_2_iniciado := false
var ta_olhando_pra_sala_2 := false
var jogador_na_area_final_2 := false
var final_sala_2_iniciado := false


func _ready() -> void:
	if personagem == null:
		personagem = get_node("personagem")
	camera = get_viewport().get_camera_2d()
	
	TransicaoMinigame.minigame_fechado.connect(_on_minigame_fechado)
	
func _process(_delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()

	if camera != null and camera.get_viewport() != get_viewport():
		camera = get_viewport().get_camera_2d()

	processar_fase_sala_1()

func processar_fase_sala_1() -> void:
	match fase_sala_1:
		FASE_SALA_1.CAIXAS_1:
			if grupo_esta_vazio("quebraveis"):
				fase_sala_1 = FASE_SALA_1.CAIXAS_2
				spawn_caixas()

		FASE_SALA_1.CAIXAS_2:
			if grupo_esta_vazio("quebraveis"):
				fase_sala_1 = FASE_SALA_1.PREPARANDO_DUMMY
				iniciar_fase_dummy()

		FASE_SALA_1.DUMMY:
			if grupo_esta_vazio("dummy"):
				fase_sala_1 = FASE_SALA_1.FINALIZANDO
				iniciar_dialogo_final_sala_1()


func grupo_esta_vazio(grupo: String) -> bool:
	return get_tree().get_nodes_in_group(grupo).is_empty()


## SALA 1

func quando_ver_o_npc_fullstack_tutorial_comecar_tutorial() -> void:
	if fase_sala_1 != FASE_SALA_1.INICIO:
		return

	fase_sala_1 = FASE_SALA_1.TUTORIAL_INICIAL

	personagem.lock_movimentacao()
	camera.lock_camera()

	await camera.transitar_personagem(npc, 2)

	npc.limite_dialogo = 4
	npc.iniciar_dialogo()

	await npc.dialogo_finalizado

	await camera.transitar_personagem(personagem, 1)

	camera.unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(1).timeout

	fase_sala_1 = FASE_SALA_1.CAIXAS_1
	spawn_caixas()


func spawn_caixas() -> void:
	var caixa_1 = CENA_CAIXA.instantiate()
	caixa_1.global_position = spawn_caixa_1.global_position
	add_child(caixa_1)
	caixa_1.animacao_inicial()

	var caixa_2 = CENA_CAIXA.instantiate()
	caixa_2.global_position = spawn_caixa_2.global_position
	add_child(caixa_2)
	caixa_2.animacao_inicial()


func iniciar_fase_dummy() -> void:
	print("começo fase dummy tutorial sala 1")

	personagem.lock_movimentacao()
	camera.lock_camera()

	await camera.transitar_personagem(npc, 2)

	npc.limite_dialogo = 7
	npc.iniciar_dialogo(4)

	await npc.dialogo_finalizado

	await camera.transitar_personagem(dummy, 1)
	get_tree().call_group("dummy", "definir_demonstracao", true)

	await camera.transitar_personagem(dummy_4, 1)
	
	await camera.transitar_personagem(personagem, 1)

	camera.unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(0.5).timeout
	get_tree().call_group("dummy", "definir_demonstracao", false)
	
	get_tree().call_group("dummy", "ativar_dummy")

	fase_sala_1 = FASE_SALA_1.DUMMY


func iniciar_dialogo_final_sala_1() -> void:
	await get_tree().create_timer(0.5).timeout

	personagem.lock_movimentacao()
	camera.lock_camera()

	await camera.transitar_personagem(npc, 2)

	npc.limite_dialogo = 9
	npc.iniciar_dialogo(7)

	await npc.dialogo_finalizado

	await camera.transitar_personagem(personagem, 1)

	camera.unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(0.5).timeout

	npc.teleportar_para(posicao_final_1)

	await get_tree().create_timer(0.35).timeout

	# porta 1
	# get_node("parede/porta_1").abrir_porta("esquerda")

	fase_sala_1 = FASE_SALA_1.FINALIZADA


## SALA 2

func _on_porta_1_alguem_atravessou(indo_para_fora: bool) -> void:
	if indo_para_fora:
		await get_tree().create_timer(0.25).timeout
		npc.teleportar_para(posicao_final_1)
		return

	if tutorial_sala_2_iniciado:
		return

	tutorial_sala_2_iniciado = true

	await get_tree().create_timer(0.25).timeout
	npc.teleportar_para(posicao_inicial_2)

	if not ta_olhando_pra_sala_2:
		return

	personagem.lock_movimentacao()
	camera.lock_camera()

	await camera.transitar_personagem(npc, 1.5)

	npc.limite_dialogo = 13
	npc.iniciar_dialogo(10)

	await npc.dialogo_finalizado

	await camera.transitar_personagem(get_node("Bebedouro"), 2)

	for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
		bebedouro.atirar()

	await get_tree().create_timer(0.5).timeout

	await camera.transitar_personagem(personagem, 0.5)

	camera.unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(1).timeout

	for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
		bebedouro.ativo = true


func _on_visible_on_screen_fase_2_screen_entered() -> void:
	ta_olhando_pra_sala_2 = true


func _on_visible_on_screen_fase_2_screen_exited() -> void:
	ta_olhando_pra_sala_2 = false


func _on_visible_on_screen_final_2_screen_entered() -> void:
	jogador_na_area_final_2 = true


func _on_porta_2_alguem_atravessou(indo_para_fora: bool) -> void:
	if indo_para_fora:
		return

	if not jogador_na_area_final_2:
		return

	finalizar_sala_2()


func finalizar_sala_2() -> void:
	if final_sala_2_iniciado:
		return

	final_sala_2_iniciado = true

	camera.lock_camera()
	personagem.lock_movimentacao()

	npc.teleportar_para(posicao_final_2)

	await camera.transitar_personagem(npc, 2)

	npc.limite_dialogo = 19
	npc.iniciar_dialogo(15)

	await npc.dialogo_finalizado

	await camera.transitar_personagem(personagem, 0.5)

	camera.unlock_camera()
	personagem.unlock_movimentacao()

	porta_2.fechar_porta()

	boss = cena_boss.instantiate()
	boss.global_position = posicao_final_2.global_position
	add_child(boss)
	boss.fase_2_iniciar.connect(iniciar_fase_2)
	npc.queue_free()
	
	


func _on_porta_2_abriu() -> void:
	for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
		bebedouro.ativo = false

var proxima_cena := preload("res://cenas_tscn/inimigos_tscn/boss_tscn/fullstack_tscn/minigame_fullstack_rpg_cena.tscn")

func iniciar_fase_2() -> void:
	camera.lock_camera()
	personagem.lock_movimentacao()
	
	camera.transitar_personagem(boss, 2)
	await get_tree().create_timer(1.75).timeout
	TransicaoMinigame.abrir_minigame(CAMINHO_MINIGAME)


func _on_minigame_fechado() -> void:
	await camera.transitar_personagem(boss, 1)
	
	boss.limite_dialogo = 4
	boss.iniciar_dialogo()
	await boss.dialogo_finalizado
	var npc2 = npc_fullstack_cena.instantiate()
	npc2.global_position = boss.global_position
	add_child(npc2)
	boss.queue_free()
	await get_tree().create_timer(0.1).timeout
	npc2.teleportar_para(posicao_final_1)
	await camera.transitar_personagem(personagem, 2)
	camera.unlock_camera()
	personagem.unlock_movimentacao()
	print("o minigame terminou e o tutorial voltou ao normal")

	
