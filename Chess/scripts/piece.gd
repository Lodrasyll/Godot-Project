extends Node2D

@onready var piece_sprite = get_node("Sprite2D")

const SPRITE_SIZE = 16
const CELL_SIZE = 64

const X_OFFSET = 44 + 32
const Y_OFFSET = 44 + 32

@export var piece_type = Globals.PIECE_TYPES
@export var piece_color = Globals.COLORS
@export var board_position: Vector2

var board_handle; #这里应该是为了交换棋盘的控制权，而设置的变量

@export var moved: bool;

func init_piece(type: Globals.PIECE_TYPES, col: Globals.COLORS, board_pos: Vector2, board):
	piece_type = type
	piece_color = col
	board_position = board_pos
	board_handle = board
	moved = false

	update_piece_sprite()
	
	position = Vector2(
		X_OFFSET + board_position[0] * CELL_SIZE,
		Y_OFFSET + board_position[1] * CELL_SIZE,
	)
	
func update_piece_sprite():
	if piece_sprite:
		var region_pos = Globals.SPRITE_MAPPING[piece_color][piece_type] #根据字典的键来分配图片中的棋子
		# region_rect 显示的图集纹理区域。[默认： Rect2(0, 0, 0, 0)] set_region_rect（值） setter get_region_rect() getter
		piece_sprite.region_rect = Rect2(
			region_pos.x * SPRITE_SIZE, # 格子左上角的x像素
			region_pos.y * SPRITE_SIZE, # 格子左上角的x像素
			SPRITE_SIZE,				# 宽度（每个格子的像素宽度）
			SPRITE_SIZE,				# 高度（每个格子的像素高度）
		)
		

func move_position(to_move: Vector2):
	moved = true
	board_position = to_move
	position = Vector2(
		X_OFFSET + board_position[0] * CELL_SIZE,
		Y_OFFSET + board_position[1] * CELL_SIZE,
	)
	
	
	
