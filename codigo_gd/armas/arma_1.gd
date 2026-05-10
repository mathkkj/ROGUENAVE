class_name ArmasRanged
extends Node2D

@onready var bala_cena = preload("res://cenas_tscn/armas/bala.tscn")
@onready var sair_bala = get_node("sair_bala")


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func atirar():
	var bala = bala_cena.instantiate()
	bala.global_position = sair_bala.global_position
	bala.rotation = sair_bala.global_rotation
	#CONECTAR O SINAL DA BALA NO CODIGO DO PLAYER
	bala.acertou.connect(get_parent()._on_bala_acertou)
	get_tree().current_scene.add_child(bala)
