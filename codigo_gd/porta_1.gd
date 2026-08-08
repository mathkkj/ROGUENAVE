extends Node2D
class_name Porta

signal alguem_atravessou(indo_para_fora: bool)

@onready var area_porta = get_node("area_porta")
@onready var porta = get_node("porta")

@export var distancia_abertura: float = 64.0
@export var duracao: float = 1.2

@export_enum("cima", "baixo", "esquerda", "direita")
var direcao_entrada: String = "direita"

@onready var collision: CollisionShape2D = porta.get_node("CollisionShape2D")

var aberta := false
var posicao_fechada: Vector2

var personagem: Node2D = null
var posicao_entrada: Vector2


func _ready() -> void:
	posicao_fechada = porta.position




func abrir_porta(direcao: String) -> void:
	if aberta:
		return

	var vetor_direcao := Vector2.ZERO

	match direcao:
		"cima":
			vetor_direcao = Vector2.UP

		"baixo":
			vetor_direcao = Vector2.DOWN

		"esquerda":
			vetor_direcao = Vector2.LEFT

		"direita":
			vetor_direcao = Vector2.RIGHT

		_:
			push_warning("Direção inválida: " + direcao)
			return

	aberta = true

	var posicao_final := posicao_fechada + vetor_direcao * distancia_abertura

	await get_tree().create_timer(0.15).timeout

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		porta,
		"position",
		posicao_final,
		duracao
	)

	await tween.finished

	collision.disabled = true



func _on_area_porta_body_entered(body: Node2D) -> void:
	if not body.is_in_group("jogador"):
		return

	personagem = body
	posicao_entrada = personagem.global_position

func _on_area_porta_body_exited(body: Node2D) -> void:
	
	if body != personagem:
		return

	var deslocamento := personagem.global_position - posicao_entrada

	var vetor_entrada := Vector2.ZERO

	match direcao_entrada:
		"cima":
			vetor_entrada = Vector2.UP

		"baixo":
			vetor_entrada = Vector2.DOWN

		"esquerda":
			vetor_entrada = Vector2.LEFT

		"direita":
			vetor_entrada = Vector2.RIGHT

	var foi_na_direcao_da_entrada := deslocamento.dot(vetor_entrada) > 0.0

	var indo_para_fora := not foi_na_direcao_da_entrada

	alguem_atravessou.emit(indo_para_fora)

	personagem = null
