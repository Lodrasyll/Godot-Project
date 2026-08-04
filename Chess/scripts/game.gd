extends Node2D

@export var pieces = [] #使用数组作为游戏内出现的棋子
@export var piece_scene = preload("res://scenes/Piece.tscn") #加载提前做好的棋子场景对象

#为了评估检查或游戏结束逻辑，需要追踪黑白王的位置
@export var black_king_position: Vector2
@export var white_king_position: Vector2

const CELL_SIZE: int = 64
var board_offset = (DisplayServer.window_get_size().x - CELL_SIZE * 8) / 2

# Called when the node enters the scene tree for the first time.
func _ready():
	var BG = ColorRect.new()
	var board_line_1 = ColorRect.new()
	var board_line_2 = ColorRect.new()
	BG.color = Color()
	BG.size = get_window().size
	BG.z_index = -200
	add_child(BG)
	
	draw_board()
	
func draw_board():
	for x in range(8):
		for y in range(8):
			draw_cell(x, y)

func draw_cell(x, y):
	var rect = ColorRect.new() #ColorRect继承自Object，可以使用`Object.new()`
	rect.color = Color(0.725, 0.781, 0.681, 1.0) if (x + y) % 2 == 0 else Color(0.516, 0.28, 0.24, 1.0) #三元运算符：结果A if 条件 else 结果B
	rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	rect.position = Vector2(
		x * CELL_SIZE + board_offset,
		y * CELL_SIZE + board_offset
	)
	rect.z_index = -100
	add_child(rect)
