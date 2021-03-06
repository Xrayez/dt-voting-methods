extends Control

onready var panel = get_node("panel")
onready var table = get_node("table")
onready var add = get_node("add")
onready var entry = get_node("entry")
onready var condorcet = get_node("condorcet")
onready var copeland = get_node("copeland")
onready var simpson = get_node("simpson")
onready var num_votes = get_node("num_votes")
onready var protocol = get_node("protocol")

enum METHOD {
	METHOD_CONDORCET
	METHOD_COPELAND
	METHOD_SIMPSON
}
var candidates = 0
var message_log = ""
var root
var votes = {}

func _ready():
	condorcet.pressed = true
	# Set up table parameters
	table.set_hide_root(true)
	table.set_column_titles_visible(true)
	table.set_columns(2)
	table.set_column_title(0, "Votes")
	table.set_column_title(1, "Candidates rank")
	# Create table
	root = table.create_item()

func _input(event):
	if event.is_action_pressed("enter"):
		add_rank()
		show()
	if event.is_action_pressed("delete"):
		remove_rank()
		show()

func _on_add_pressed():
	add_rank()
	show()

func _on_remove_pressed():
	remove_rank()
	show()

func add_rank():
	# Adds a rank to the table
	# If rank exists, it will increase number of votes for that rank
	var rank = Array(entry.text.split(" "))
	if votes.has(rank):
		votes[rank] += int(num_votes.text)
	else:
		votes[rank] = 0
		votes[rank] += int(num_votes.text)

	# Compute number of candidates automatically
	candidates = 0
	for rank in votes.keys():
		candidates = max(candidates, rank.size())

func remove_rank():
	# Removes a rank from the table
	var rank = Array(entry.text.split(" "))
	if votes.has(rank):
		votes[rank] -= int(num_votes.text)
		if votes[rank] <= 0:
			votes.erase(rank)

	# Compute number of candidates automatically
	candidates = 0
	for rank in votes.keys():
		candidates = max(candidates, rank.size())

func show():
	# Clear table
	while root.get_children() != null:
		root.remove_child(root.get_children())

	# Fill table
	for rank in votes.keys():
		var item = table.create_item(root)
		item.set_text(0, str(votes[rank]))
		var string = String(rank)
		item.set_text(1, string)

	entry.grab_focus()

func determine_winner(method = METHOD_CONDOCET):
	# Init opponents matrix
	var opponents = []
	for j in range(candidates):
		opponents.append([])
		for i in range(candidates):
			opponents[j].append(0)

	# Sum up total number of votes for each candidate pair
	for j in range(candidates):
		for i in range(candidates):
			if j == i: continue
			for rank in votes.keys():
				var a = rank.find(str(j + 1))
				var b = rank.find(str(i + 1))
				if a < b: opponents[j][i] = votes[rank]

	# Init score for each candidate
	var score = []
	score.resize(candidates)
	for a in range(candidates):
		score[a] = 0

	#----------------------------
	# Condorcet method
	#----------------------------
	if method == METHOD_CONDORCET:
		for j in range(candidates):
			for i in range(candidates):
				if j == i: continue
				if opponents[j][i] > opponents[i][j]:
					score[j] += 1
			if score[j] == candidates - 1:
				message_log += "Condorcet winner is " + str(j + 1) + "\n"
				return
		message_log += "There is no Condorcet winner\n"
	#---------------------------
	# Copeland method
	#---------------------------
	elif method == METHOD_COPELAND:
		for j in range(candidates):
			for i in range(candidates):
				if j == i: continue
				if opponents[j][i] > opponents[i][j]:
					score[j] += 1
				elif opponents[j][i] < opponents[i][j]:
					score[j] -= 1
		var max_score = -1000000
		for a in range(candidates):
			max_score = max(max_score, score[a])
		var winner = score.find(max_score)
		message_log += "Copeland winner is " + str(winner + 1) + "\n"
		return
	#----------------------------
	# Simpson (Minimax) method
	#----------------------------
	elif method == METHOD_SIMPSON:
		for j in range(candidates):
			var total_votes = []
			for i in range(candidates):
				if j == i: continue
				total_votes.append(opponents[j][i])
			var min_score = 1000000
			for a in range(total_votes.size()):
				min_score = min(min_score, total_votes[a])
			score[j] = min_score
		var max_score = -1000000
		for a in range(candidates):
			max_score = max(max_score, score[a])
		var winner = score.find(max_score)
		message_log += "Simpson winner is " + str(winner + 1) + "\n"
		return

func _on_calc_pressed():
	if not (condorcet.pressed or copeland.pressed or simpson.pressed):
		message_log += "Please select the method above" + "\n"
	if condorcet.pressed:
		determine_winner(METHOD_CONDORCET)
	if copeland.pressed:
		determine_winner(METHOD_COPELAND)
	if simpson.pressed:
		determine_winner(METHOD_SIMPSON)

	protocol.set_text(message_log)
	message_log += "\n"
	protocol.cursor_set_line(protocol.get_line_count())


func _on_table_item_selected():
	var item = table.get_selected()
	num_votes.text = item.get_text(0)
	entry.text = item.get_text(1).replace("[", "").replace("]", "").replace(",", "")
