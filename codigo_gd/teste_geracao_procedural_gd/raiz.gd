extends Node2D

var base = preload("res://cenas_tscn/teste_geracao_procedural_tscn/base.tscn")

var mapa = null

var personagem

const lista_mapas = {
	"direita": [
		"sala1"
	],
	"esquerda": [
		"base"
	]
}


func _ready() -> void:
	mapa = base.instantiate()
	add_child(mapa)

	personagem = Global.personagem


func verificar_direcao_saida() -> String:
	var posicao = personagem.global_position

	if posicao.x < 0:
		return "esquerda"

	if posicao.x > 560:
		return "direita"

	if posicao.y < 0:
		return "cima"

	if posicao.y > 315:
		return "baixo"

	return ""


func _physics_process(_delta):
	var direcao = verificar_direcao_saida()

	if direcao != "":
		carregar_mapa(direcao)


func carregar_mapa(direcao):
	mapa.queue_free()

	var nome_mapa = lista_mapas[direcao].pick_random()

	var carregar = load("res://cenas_tscn/teste_geracao_procedural_tscn/" + nome_mapa + ".tscn")

	mapa = carregar.instantiate()
	add_child(mapa)

	# coloca o jogador no lado oposto
	if direcao == "direita":
		personagem.global_position.x = 20

	elif direcao == "esquerda":
		personagem.global_position.x = 540

	elif direcao == "cima":
		personagem.global_position.y = 295

	elif direcao == "baixo":
		personagem.global_position.y = 20
