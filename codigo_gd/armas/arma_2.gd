class_name ArmaMeele
extends Node2D

@export var tempo_entre_golpes: float = 0.5
@export var tempo_reset_combo: float = 1.5
@export var total_golpes: int = 3

signal golpe_executado(golpe: int)

var combo_atual: int = 0
var timer_combo: float = 0
var atacando: bool = false

func _ready() -> void:
	visible = false
	pass

func _process(delta: float) -> void:
	z_index = global_position.y
	if timer_combo > 0.0:
		timer_combo = max(0.0, timer_combo - delta)

	if timer_combo <= 0.0 and not atacando:
		combo_atual = 0
			
			
		

func atacar() -> void:
	
	if atacando:
		return

	atacando = true
	visible = true

	combo_atual += 1
	if combo_atual > total_golpes:
		combo_atual = 1

	_executar_golpe(combo_atual)

	timer_combo = tempo_reset_combo
	await get_tree().create_timer(tempo_entre_golpes).timeout

	atacando = false
	visible = false
	if timer_combo <= 0.0:
		combo_atual = 0

func _executar_golpe(golpe: int) -> void:
	emit_signal("golpe_executado", golpe)

	match golpe:
		1:
			print("golpe 1")
		2:
			print("golpe 2")
		3:
			print("golpe 3")
