class_name ArmasRanged
extends Node2D

@onready var bala_cena = preload("res://cenas_tscn/armas/bala.tscn")
@onready var sair_bala = get_node("sair_bala")
@onready var sprite = get_node("Sprite2D")

var calor = 0.0
var calor_maximo = 100.0
var calor_por_tiro = 20.0
var resfriamento = 50.0


var superaquecida = false



var pode_atirar = true

func _physics_process(delta: float) -> void:
	
	if calor > 0:
		calor -= resfriamento * delta
		
	var cor_normal = remap(calor, 0, 100, 255, 0)
	#print(calor)

		
	self.modulate = Color.from_rgba8(255, cor_normal, cor_normal, 255)
	
	
	
	if superaquecida and calor <= calor_maximo * 0.5: 
		superaquecida = false


func atirar():
	if not superaquecida and calor < calor_maximo:
		pode_atirar = true
	else:
		pode_atirar = false
		
	
	if pode_atirar:
		calor += calor_por_tiro
		
		
		if calor >= calor_maximo:
			superaquecida = true
		
		var bala = bala_cena.instantiate()
		bala.global_position = sair_bala.global_position
		bala.rotation = sair_bala.global_rotation
		#CONECTAR O SINAL DA BALA NO CODIGO DO PLAYER
		bala.acertou.connect(get_parent()._on_bala_acertou)
		
		get_tree().current_scene.add_child(bala)
