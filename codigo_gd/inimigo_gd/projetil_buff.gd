extends Area2D

@export var tipo_buff = -1
@onready var animacao = get_node("AnimatedSprite2D")

@onready var cena_particula = preload("res://cenas_tscn/inimigos_tscn/explosao_destruiacao_bala.tscn")

@export var cor1 = Color(1.0, 0.0, 0.0, 1.0) 
@export var cor0 = Color(1.0, 0.391, 0.652, 1.0) 
var cor : Color

@export var buff_velocidade := 1.5
@export var buff_escudo := 6
@export var duracao_buff := 5


var p0: Vector2
var p1: Vector2
var p2: Vector2
var t := 0.0
@export var velocidade := 2

func iniciar_curva(_p0: Vector2, _p1: Vector2, _p2: Vector2) -> void:
	p0 = _p0
	p1 = _p1
	p2 = _p2
	global_position = p0

func _process(delta: float) -> void:
	t += delta * velocidade
	global_position = _quadratic_bezier(p0, p1, p2, t)

	if t >= 1.0:
		for body in get_overlapping_bodies():
			if body.is_in_group("inimigos"):
				body.receber_buff(buff_velocidade, buff_escudo, duracao_buff, tipo_buff)
				
		var particula = cena_particula.instantiate()
		particula.get_child(0).color = cor
		particula.position = global_position
		get_tree().current_scene.add_child(particula)
		queue_free()

func _physics_process(delta: float) -> void:
	match tipo_buff:
		0:
			cor = cor0
			animacao.play("velocidade")
		1:
			cor = cor1
			animacao.play("escudo")


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)
