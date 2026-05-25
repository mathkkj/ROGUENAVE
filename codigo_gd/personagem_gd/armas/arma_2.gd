class_name ArmaMeele
extends Node2D

@export var tempo_entre_golpes: float = 0.5
@export var tempo_reset_combo: float = 1.5
@export var total_golpes: int = 3

signal golpe_executado(golpe: int)

var input_buffer := false
var buffer_time := 0.15
var buffer_timer := 0.0

var combo_atual: int = 0
var timer_combo: float = 0
var atacando: bool = false
@onready var hitbox = get_node("hitbox")
@onready var hitbox_col = get_node("hitbox/CollisionShape2D")

func pedir_ataque() -> void:
	input_buffer = true
	buffer_timer = buffer_time

func _ready() -> void:
	hitbox_col.disabled = true
	visible = false
	pass

func _physics_process(delta: float) -> void:
	if buffer_timer > 0:
		buffer_timer -= delta

	if buffer_timer <= 0:
		input_buffer = false
	
	z_index = global_position.y
	if timer_combo > 0.0:
		timer_combo = max(0.0, timer_combo - delta)

	if timer_combo <= 0.0 and not atacando:
		combo_atual = 0
			
			
		

func atacar() -> void:
	if not input_buffer and atacando:
		return
	
	input_buffer = false
	buffer_timer = 0.0
	
	atacando = true
	visible = true
	hitbox.monitoring = true
	hitbox_col.disabled = false

	combo_atual += 1
	if combo_atual > total_golpes:
		combo_atual = 1

	_executar_golpe(combo_atual)

	timer_combo = tempo_reset_combo
	await get_tree().create_timer(tempo_entre_golpes).timeout

	
	
	if timer_combo > 0:
		timer_combo -= get_process_delta_time()
		
		if timer_combo <= 0:
			combo_atual = 0
	atacando = false
	visible = false
	hitbox.monitoring = false
	hitbox_col.disabled = true

func _executar_golpe(golpe: int) -> void:
	emit_signal("golpe_executado", golpe)

	match golpe:
		1:
			print("golpe 1")
		2:
			print("golpe 2")
		3:
			print("golpe 3")
