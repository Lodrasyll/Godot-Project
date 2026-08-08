extends Node2D

#游戏状态，游戏主要逻辑
var player_color
var status # 谁正在玩/操作
var player2_type # 

# 拖动棋子
var is_dragging: bool # 变量：是/否处于拖动状态
var selected_piece: Piece = null
var pervious_position = null # 能被接受的位置：棋子正确走法检测

@onready var board = get_node("Board")

# Called when the node enters the scene tree for the first time.
func _ready():
	init_game()

func _input(event):
	# 鼠标左键点击/拖动 鼠标点击后释放的位置就是棋子走的位置
	if Input.is_action_just_pressed("left_click"):
		var pos = get_pos_under_mouse()
		selected_piece = board.get_piece(pos)
		# 只有在鼠标下或当前回合的棋子才能拖动
		if selected_piece == null or selected_piece.piece_color != status:
			return
		is_dragging = true
		pervious_position = selected_piece.position
		selected_piece.z_index= 100
		
	elif event is InputEventMouseMotion and is_dragging:
		selected_piece.position = get_global_mouse_position()
		
	elif Input.is_action_just_released("left_click") and is_dragging:
		var is_valid_move = drop_piece()
		if ! is_valid_move:
			selected_piece.position = pervious_position
		selected_piece.z_index = 1
		selected_piece = null
		is_dragging = false
		

func init_game():
	is_dragging = false
	player_color = Globals.COLORS.WHITE
	status = Globals.COLORS.WHITE
	player2_type = Globals.PLAYER_2_TYPE.HUMAN

func get_pos_under_mouse():
	var pos = get_global_mouse_position()
	pos -= Vector2(board.board_offset, board.board_offset)
	pos.x = int(pos.x / Globals.CELL_SIZE)
	pos.y = int(pos.y / Globals.CELL_SIZE)
	return pos

func drop_piece():
	var to_move = get_pos_under_mouse()
	if valid_move(selected_piece.board_position, to_move):
		# 对合法移动：
		# - 如果目标点有棋子，那吃掉对方
		var dest_piece = board.get_piece(to_move)
		# 只能吃掉不同颜色方的棋子
		if dest_piece != null and dest_piece.piece_color != selected_piece.piece_color:
			board.delete_piece(dest_piece) # 棋盘对象类下的删除棋子函数 参数是对象的棋子
		
		selected_piece.move_position(to_move)
		# - 改变现在的活动棋方的状态
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		return true
	return false

func valid_move(from_pos, to_pos):
	var board_copy = board.clone()
	var src_piece = board_copy.get_piece(from_pos)
	
	# 如果我们无法移动到被威胁的位置或可移动的位置
	if (to_pos not in src_piece.get_moveable_positions() and 
		to_pos not in src_piece.get_threatened_positions()
	):
		board_copy.queue_free() # 👈 清理临时棋盘
		return false
	
	var dst_piece = board_copy.get_piece(to_pos)
	if dst_piece != null:
		board_copy.delete_piece(dst_piece)
	src_piece.move_position(to_pos)
	
	# 检查当前方（指定颜色的棋子）是否未处于被将军（将军威胁）的状态
	for piece in board_copy.pieces:
		if status == Globals.COLORS.BLACK and board_copy.black_king_position in piece.get_threatened_positions():
			board_copy.queue_free() # 👈 清理临时棋盘
			return false
		if status == Globals.COLORS.WHITE and board_copy.white_king_position in piece.get_threatened_positions():
			board_copy.queue_free() # 👈 清理临时棋盘
			return false
	
	return true
