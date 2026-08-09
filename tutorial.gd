extends Node2D


@onready var cena_caixa = preload("res://cenas_tscn/caixa.tscn")

@export var personagem: CharacterBody2D
var ja_vi_1_dialogo_tutorial_sala_1 := false
var ja_vi_1_dialogo_tutorial_sala_2 := false

var ja_spawnou_caixa := false
var fase_caixas := 0


@onready var spawn_caixa_1 = get_node("caixas_spanwpoints/caixa_1")
@onready var spawn_caixa_2 = get_node("caixas_spanwpoints/caixa_2")

var dialogo_final_ja_iniciado := false

func _ready():
	if personagem == null:
		personagem = get_node("personagem")
		


func _physics_process(delta: float) -> void:
	
	#mudança de fases (pra progredir no tutorial da sala 1)
	if ja_spawnou_caixa and get_tree().get_nodes_in_group("quebraveis").is_empty():
		match fase_caixas:
			1:
				
				fase_caixas = 2
				spawn_caixa()

			2:
				fase_caixas = 3
				iniciar_fase_dummy()

			3:
				pass
	
	if get_tree().get_nodes_in_group("dummy").is_empty() and not dialogo_final_ja_iniciado:
		dialogo_final_ja_iniciado = true
		iniciar_dialogo_final_sala_1()
		
##SALA 1

func quando_ver_o_npc_fullstack_tutorial_comecar_tutorial() -> void:
	if ja_vi_1_dialogo_tutorial_sala_1:
		return
	

	ja_vi_1_dialogo_tutorial_sala_1 = true
	personagem.lock_movimentacao()

	get_viewport().get_camera_2d().lock_camera()
	await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 2)

	get_node("NPC Fullstack").iniciar_dialogo()
	get_node("NPC Fullstack").limite_dialogo = 4
	await get_node("NPC Fullstack").dialogo_finalizado

	await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 1)

	get_viewport().get_camera_2d().unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(1).timeout
	ja_spawnou_caixa = true
	fase_caixas = 1
	spawn_caixa()



func spawn_caixa():
	#spawn caixa nos marcadores
	var caixa1 = cena_caixa.instantiate()
	caixa1.global_position = spawn_caixa_1.global_position
	add_child(caixa1)
	caixa1.animacao_inicial()

	var caixa2 = cena_caixa.instantiate()
	caixa2.global_position = spawn_caixa_2.global_position
	add_child(caixa2)
	caixa2.animacao_inicial()

func iniciar_fase_dummy():
	print("começo fase dummy tutorial sala 1")
	personagem.lock_movimentacao()
	get_viewport().get_camera_2d().lock_camera()
	await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 2)

	
	get_node("NPC Fullstack").limite_dialogo = 7
	get_node("NPC Fullstack").iniciar_dialogo(4)

	await get_node("NPC Fullstack").dialogo_finalizado
	await get_viewport().get_camera_2d().transitar_personagem(get_node("Dummy"), 1)
	get_tree().call_group("dummy", "tocar_animacao", "idle")
	
	await get_viewport().get_camera_2d().transitar_personagem(get_node("Dummy4"), 1)
	await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 1)

	get_viewport().get_camera_2d().unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(0.5).timeout
	get_tree().call_group("dummy", "ativar_dummy")

func iniciar_dialogo_final_sala_1():
	await get_tree().create_timer(0.5).timeout
	personagem.lock_movimentacao()

	get_viewport().get_camera_2d().lock_camera()
	await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 2)

	get_node("NPC Fullstack").limite_dialogo = 9
	get_node("NPC Fullstack").iniciar_dialogo(7)
	await get_node("NPC Fullstack").dialogo_finalizado

	await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 1)

	get_viewport().get_camera_2d().unlock_camera()
	personagem.unlock_movimentacao()

	await get_tree().create_timer(0.5).timeout
	get_node("NPC Fullstack").teleportar_para(get_node("posicoes/final_1"))
	await get_tree().create_timer(0.35).timeout
	#get_node("parede/porta_1").abrir_porta("esquerda")


##SALA 2
var ta_olhando_pra_sala_2 := false
func _on_porta_1_alguem_atravessou(indo_para_fora: bool) -> void:
	print("estou indo para fora? ",indo_para_fora)
	if ja_vi_1_dialogo_tutorial_sala_2:
			return
	ja_vi_1_dialogo_tutorial_sala_2 = true
		
	if indo_para_fora == false:
		
		
		await get_tree().create_timer(0.25).timeout
		get_node("NPC Fullstack").teleportar_para(get_node("posicoes/inicial_2"))
		#DIALOGO:
		if ta_olhando_pra_sala_2:
			get_viewport().get_camera_2d().lock_camera()
			personagem.lock_movimentacao()

			await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 1.5)

			get_node("NPC Fullstack").limite_dialogo = 13
			get_node("NPC Fullstack").iniciar_dialogo(10)
			await get_node("NPC Fullstack").dialogo_finalizado

			await get_viewport().get_camera_2d().transitar_personagem(get_node("Bebedouro"), 2)
			
			for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
				bebedouro.atirar()
			await get_tree().create_timer(0.5).timeout
			
			#get_node("NPC Fullstack").limite_dialogo = 14
			#get_node("NPC Fullstack").iniciar_dialogo(13)
			

			await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 0.5)

			get_viewport().get_camera_2d().unlock_camera()
			personagem.unlock_movimentacao()
			
			await get_tree().create_timer(1).timeout
			for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
				bebedouro.ativo = true
			
			


	else:
		
		await get_tree().create_timer(0.25).timeout
		get_node("NPC Fullstack").teleportar_para(get_node("posicoes/final_1"))
	

func _on_visible_on_screen_fase_2_screen_entered() -> void:
	ta_olhando_pra_sala_2 = true


func _on_visible_on_screen_fase_2_screen_exited() -> void:
	ta_olhando_pra_sala_2 = false



var ja_viu_final_2 := false
var jogador_na_area_final_2 := false
func _on_visible_on_screen_final_2_screen_entered() -> void:
	jogador_na_area_final_2 = true


func _on_porta_2_alguem_atravessou(indo_para_fora: bool) -> void:

	
	if not jogador_na_area_final_2:
		return
	if indo_para_fora == false:
		finalizar_sala_2()
	else:
		return


func finalizar_sala_2() -> void:
	if ja_viu_final_2:
		return
	
	ja_viu_final_2 = true
	
	var camera := get_viewport().get_camera_2d()
	var npc := get_node("NPC Fullstack")
	var posicao_final := get_node("posicoes/final_2")
	
	camera.lock_camera()
	personagem.lock_movimentacao()
	
	npc.teleportar_para(posicao_final)
	await get_viewport().get_camera_2d().transitar_personagem(get_node("NPC Fullstack"), 2)
	get_node("NPC Fullstack").limite_dialogo = 19
	get_node("NPC Fullstack").iniciar_dialogo(15)
	await get_node("NPC Fullstack").dialogo_finalizado

	await get_viewport().get_camera_2d().transitar_personagem(get_node("personagem"), 0.5)

	get_viewport().get_camera_2d().unlock_camera()
	personagem.unlock_movimentacao()
	get_node("parede/porta_2").fechar_porta()
	#ACABOU
	#INICIAR ULTIMA FASE

func _on_porta_2_abriu() -> void:
	for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
		bebedouro.ativo = false
