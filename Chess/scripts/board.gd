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
	draw_board()
	init_pieces()
	
func _draw():
	var BG = ColorRect.new()
	BG.color = Color()
	BG.size = get_window().size
	BG.z_index = -200
	add_child(BG)
	draw_rect(
		Rect2(Vector2(board_offset, board_offset), Vector2(CELL_SIZE * 8, CELL_SIZE * 8)), 
		Color(0.34, 0.542, 0.52, 1.0), false, 5)

func draw_board():
	for x in range(8): #range(8) 迭代器默认从0-7，提前处理好多一位的问题
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

func init_pieces():
	for piece_group in Globals.INITIAL_PIECE_SET_SINGLE:
		var piece_type = piece_group[0]
		var black_piece_pos = Vector2(piece_group[1], piece_group[2])
		var white_piece_pos = Vector2(piece_group[1],  8 - 1 - piece_group[2])
		
		#创建黑方棋子实例
		var black_piece = piece_scene.instantiate()
		add_child(black_piece)
		black_piece.init_piece(piece_type, Globals.COLORS.BLACK, black_piece_pos, self)
		pieces.append(black_piece)
		
		#创建白方棋子实例
		var white_piece = piece_scene.instantiate()
		add_child(white_piece)
		white_piece.init_piece(piece_type, Globals.COLORS.WHITE, white_piece_pos, self)
		pieces.append(white_piece)
		
		#print(JSON.stringify(pieces, "\t"))
		
		if piece_type == Globals.PIECE_TYPES.KING:
			register_king(black_piece_pos, Globals.COLORS.BLACK)
			register_king(white_piece_pos, Globals.COLORS.WHITE)

func register_king(pos, col):
	match col:
		Globals.COLORS.BLACK:
			black_king_position = pos
		Globals.COLORS.WHITE:
			white_king_position = pos

func get_piece(pos: Vector2):
	for piece in pieces:
		if piece.board_position == pos:
			return piece

func delete_piece(piece):
	for i in range(len(pieces)):
		if pieces[i] == piece:
			var popped = pieces.pop_at(i) # 移除并返回数组中位于 position 索引处的元素。
			popped.queue_free() # 释放节点队列
			return
			
func beam_search_threat(own_color, cur_x, cur_y, inc_x, inc_y):
	# 按照给定的 X/Y 增量方向（inc_x/y）沿直线移动指针
	# 以寻找受到威胁的棋子。
	var threat_pos = []
	
	cur_x += inc_x
	cur_y += inc_y
	
	# 沿增量方向持续移动，直到找到阻挡的棋子（或其他目标）
	# 或超出棋盘范围
	while cur_x >= 0 and cur_x < 8 and cur_y >= 0 and cur_y < 8:
		var cur_pos = Vector2(cur_x, cur_y)
		var cur_piece = get_piece(cur_pos)
		if cur_piece != null: # 卫语句 防止空访问
			if cur_piece.color != own_color:
				threat_pos.append(cur_pos)
			break
		
		threat_pos.append(cur_pos)
		cur_x += inc_x
		cur_y += inc_y
	
	return threat_pos

func spot_search_threat(
	own_color, cur_x, cur_y, inc_x, inc_y, threat_only = false, free_only = false
):
	# 执行单步移动，并检查该移动是否有效/合法。
	cur_x += inc_x
	cur_y += inc_y
	
	if cur_x >= 8 or cur_x < 0 or cur_y >= 8 or cur_y < 0:
		return
		
	var cur_pos = Vector2(cur_x, cur_y)
	var cur_piece = get_piece(cur_pos)
	
	if cur_piece != null:
		if free_only:
			return
		return cur_pos if cur_piece.piece_color != own_color else null
	return cur_pos if not threat_only else null


func clone():
	var board = self.duplicate()
	
	# ✅ 核心修复：给克隆棋盘一个全新的、干净的数组，彻底斩断与原棋盘的引用关系！
	board.pieces = []
	
	for i in range(len(pieces)):
		var piece = pieces[i].clone(board)
		board.pieces.append(piece.clone(board)) # 把克隆的棋子塞进新数组里
	return board
