extends StaticBody2D

@onready var bala = preload("res://cenas_tscn/inimigos_tscn/bebedouro_tscn/projetil_do_bebeddouro.tscn")
@onready var marker = get_node("Marker2D")

@export var personagem: CharacterBody2D
@export var ativo: bool = false

var quantidade_disparos := 0
var camera_lenta_desativada := false


func _on_timer_tiro_timeout() -> void:
	if not ativo:
		return

	atirar()


func atirar() -> void:
	var nova_bala = bala.instantiate()

	nova_bala.global_position = marker.global_position
	nova_bala.direcao = Vector2.LEFT
	nova_bala.bebedouro = self

	# Os 2 primeiros tiros têm câmera lenta
	if quantidade_disparos < 2 and not camera_lenta_desativada:
		nova_bala.camera_lenta = true
	else:
		nova_bala.camera_lenta = false

	# Conta o tiro
	#quantidade_disparos += 1

	get_tree().current_scene.add_child(nova_bala)


func jogador_passou_tiro() -> void:
	print("jogador passou pelo tiro")

	if quantidade_disparos >= 2:
		print("CAMERA LENTA DESATIVADA")

		for bebedouro in get_tree().get_nodes_in_group("bebedouro"):
			bebedouro.camera_lenta_desativada = true
