extends Node2D

#游戏状态，游戏主要逻辑
var player_color
var status # 谁正在玩/操作
var player2_type # 

# 拖动棋子
var is_dragging: bool # 变量：是/否处于拖动状态
var selected_piece = null
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
	if valid_move(selected_piece.position, to_move):
		# 对合法移动：
		# - 如果目标点有棋子，那吃掉对方
		var dest_piece = board.get_piece(to_move)
		# 只能吃掉不同颜色方的棋子
		if dest_piece != null and dest_piece.color != selected_piece.color:
			board.delect_piece(dest_piece)
		
		selected_piece.move_position(to_move)
		# - 改变现在的活动棋方的状态
		pass
		return true	
	return false

func valid_move(from_pos, to_pos):
	return true
