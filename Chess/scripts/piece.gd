class_name Piece
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
	
	# 如果他们移动了 更新跟踪王的位置
	if piece_type == Globals.PIECE_TYPES.KING:
		board_handle.register_king(board_position, piece_color)
	
	# 机制：兵升变为皇后
	if piece_type == Globals.PIECE_TYPES.PAWN and (
		(piece_color == Globals.COLORS.BLACK and to_move.y == 7) or # 改进版：将 to_move[1] 改为 to_move.y 更易于理解
		(piece_color == Globals.COLORS.WHITE and to_move.y == 0 )
	):
		piece_type = Globals.PIECE_TYPES.QUEEN
		update_piece_sprite() # 如果没有再次调用更新棋子图片函数，只有棋子类型变了，但渲染不变。

func clone(_board):
	var piece = self.duplicate()
	piece.board_handle = _board
	
	return piece

func get_moveable_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_move_pos()
		_: return []
		
func get_threatened_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_threat_pos()
		_: return []
		
# 兵的移动规则

const PAWN_SPOT_INCREMENTS_MOVE = [[0, 1]] # 兵只能往前走一步
const PAWN_SPOT_INCREMENTS_MOVE_FIRST = [[0, 1], [0, 2]] # 兵开局第一步能够选择往前走一步或两步
const PAWN_SPOT_INCREMENTS_TAKE = [[-1, 1], [1, 1]] # 兵只能斜向吃子

func pawn_threat_pos():
	var position = []
	
	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(
			piece_color,
			board_position[0], board_position[1],
			inc[0], inc[1] if piece_color == Globals.COLORS.BLACK else -inc[1],
			true, false
		)
		if pos != null:
			position.append(pos)
	
	return position

func pawn_move_pos():
	var position = []
	
	var increments = PAWN_SPOT_INCREMENTS_MOVE if moved else PAWN_SPOT_INCREMENTS_MOVE_FIRST
	for inc in increments:
		var pos = board_handle.spot_search_threat(
			piece_color,
			board_position[0], board_position[1],
			inc[0], inc[1] if piece_color == Globals.COLORS.BLACK else -inc[1],
			false, true
		)
		if pos != null:
			position.append(pos)
		else:
			break # 如果在第一个位置上有物体/棋子阻挡，则无法移动到第二个位置
	
	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(
			piece_color,
			board_position[0], board_position[1],
			inc[0], inc[1] if piece_color == Globals.COLORS.BLACK else -inc[1],
			true, false
		)
		if pos != null:
			position.append(pos)
	
	
	return position
