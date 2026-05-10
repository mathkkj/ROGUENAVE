extends Node2D

@export var SPEED: float = 2000.0
@export var TEMPO_DE_VIDA: float = 10.0

signal acertou(body, direcao, forca)


@export var forca: float = 400
var direcao: Vector2 = Vector2.RIGHT

func _ready() -> void:
	direcao = Vector2.RIGHT.rotated(rotation)
	await get_tree().create_timer(TEMPO_DE_VIDA).timeout
	queue_free()

func _process(delta: float) -> void:
	position += direcao.normalized() * SPEED * delta


func _on_area_2d_body_entered(body: Node2D) -> void:
	emit_signal("acertou", body, direcao, forca)
	queue_free() # destrói a bala depois de bater
