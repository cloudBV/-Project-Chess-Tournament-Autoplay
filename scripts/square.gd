extends Button

var board_row : int = 0
var board_col : int = 0
var piece_instance = null

@onready var base_color = $BaseColor
@onready var move_highlight = $MoveHighlight

func set_highlight(is_on : bool):
	move_highlight.visible = is_on

func set_base_color(color : Color):
	base_color.color = color

func place_piece(piece):
	piece_instance = piece
	add_child(piece)
	piece.position = Vector2(size.x / 2,size.y / 2)

func remove_piece():
	if piece_instance:
		piece_instance.queue_free()
		piece_instance = null

func release_piece():
	var p = piece_instance
	if p:
		remove_child(p)
	piece_instance = null
	return p

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
