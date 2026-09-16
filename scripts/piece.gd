extends Node2D

var piece_type : String = "" # 'pawn','knight','bishop','rook','queen','king'
var piece_color : String = "" #'white' or 'black'

@onready var sprite = $Sprite2D

func setup(type: String, color: String, texture: Texture2D):
	piece_type = type
	piece_color = color
	sprite.texture = texture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
