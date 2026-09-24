extends Node2D

var base = preload("res://cenas_tscn/teste_geracao_procedural_tscn/base.tscn")

var mapa = null

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
	
func carregar_mapa(direcao):
	mapa.queue_free()
	var nome_mapa = lista_mapas[direcao].pick_random()
	var carregar = load("res://cenas_tscn/teste_geracao_procedural_tscn/"+nome_mapa+".tscn")
	mapa = carregar.instantiate()
	add_child(mapa)
