extends Resource
class_name ChallengeBank
# Holds every line of code and deals them out for the stage being played.
# Pick the stage with set_stage(chapter, stage), then ask for challenges with
# next_challenge("fill") or next_challenge("output"). Cards don't repeat until
# that stage's deck of the same kind has been used up.
# (The Challenge class below is part of this file, so no other script is needed.)

class Challenge extends Resource:
	# One line of code shown by an enemy.
	#   FILL   - part of the line is missing ("____"); the player types the missing part.
	#            A line with 2+ blanks is answered with the parts separated by commas.
	#   OUTPUT - the line is complete; the player types what it prints.
	# chapter / stage say where it belongs (0 = the general set).

	const FILL = "fill"
	const OUTPUT = "output"

	var kind: String
	var code: String
	var answers: Array
	var chapter: int
	var stage: int

	func _init(p_kind: String, p_code: String, p_answers: Array, p_chapter: int = 0, p_stage: int = 0):
		kind = p_kind
		code = p_code
		answers = p_answers
		chapter = p_chapter
		stage = p_stage

	# Small caption shown above the code.
	func get_instruction() -> String:
		if kind == OUTPUT:
			return "what does it print?"
		var blanks = code.split("____").size() - 1
		if blanks > 1:
			return "fill in the %d blanks (comma-separated)" % blanks
		return "fill in the blank"

	# The text shown to the player. A one-line output question gets a Python prompt in front.
	func get_display_code() -> String:
		if kind == OUTPUT and not "\n" in code:
			return ">>> " + code
		return code

	func is_correct(input: String) -> bool:
		var given = _normalize(input)
		if given == "":
			return false
		for answer in answers:
			if _normalize(answer) == given:
				return true
		return false

	# Ignores spaces and quote style (' or ") but stays case-sensitive, like Python.
	func _normalize(text: String) -> String:
		return text.strip_edges().replace("'", "\"").replace(" ", "").replace("\t", "")


var _challenges = []
var _chapter: int = 1
var _stage: int = 1
var _decks = {}          # one shuffled deck per kind ("" = either kind)
var _warned: bool = false


func _init():
	_add_chapter_1()
	_add_chapter_2()
	_add_chapter_3()
	_add_general_challenges()


# Chooses which stage the challenges come from. Call it before next_challenge().
func set_stage(chapter: int, stage: int) -> void:
	_chapter = chapter
	_stage = stage
	_decks = {}
	_warned = false


# kind: "fill", "output", or "" for either.
func next_challenge(kind: String = ""):
	if kind != "fill" and kind != "output":
		kind = ""

	var deck = _decks.get(kind, [])
	if deck.empty():
		deck = _pool_for(kind)
		deck.shuffle()

	var next = deck.pop_back()
	_decks[kind] = deck
	return next


# The challenges for the current stage. While a chapter is still being written,
# this falls back to wider groups so the game never runs out of lines.
func _pool_for(kind: String) -> Array:
	var pool = _pool(kind, _chapter, _stage)
	if pool.empty():
		pool = _pool(kind, _chapter, -1)
	if pool.empty():
		if not _warned:
			push_warning("ChallengeBank: nothing written for chapter %d stage %d yet, using the general set." % [_chapter, _stage])
			_warned = true
		pool = _pool(kind, 0, -1)
	if pool.empty():
		pool = _pool(kind, -1, -1)
	return pool


# A chapter / stage of -1 means "don't filter on this".
func _pool(kind: String, chapter: int, stage: int) -> Array:
	var result = []
	for challenge in _challenges:
		if kind != "" and challenge.kind != kind:
			continue
		if chapter != -1 and challenge.chapter != chapter:
			continue
		if stage != -1 and challenge.stage != stage:
			continue
		result.append(challenge)
	return result


func _fill(code: String, answers: Array, chapter: int = 0, stage: int = 0) -> void:
	_challenges.append(Challenge.new(Challenge.FILL, code, answers, chapter, stage))


# `output` is exactly what the line prints.
func _output(code: String, output: String, chapter: int = 0, stage: int = 0) -> void:
	_challenges.append(Challenge.new(Challenge.OUTPUT, code, [output], chapter, stage))


# ======================================================================
# CHAPTER 1 - the basics of Python
#   stage 1-1: printing    stage 1-2: variables    stage 1-3: basic arithmetic
# CHAPTER 2 (below) - the same three topics, one step harder.
# CHAPTER 3 (below) - simple loops (snippets of a few lines).
# Chapters 4-5 go here as _add_chapter_4() ... once they are written.
# ======================================================================
func _add_chapter_1() -> void:
	# --- stage 1-1: printing ---
	_fill("____(\"Hello\")  # shows Hello", ["print"], 1, 1)
	_fill("print(\"Hello, ____\")  # Hello, Python", ["Python"], 1, 1)
	_fill("print____\"Hi\")  # missing bracket", ["("], 1, 1)
	_fill("print(\"Hi\"____  # missing bracket", [")"], 1, 1)
	_fill("print(____)  # shows 42", ["42"], 1, 1)
	_fill("print(\"Hi\" ____ \"!\")  # Hi!", ["+"], 1, 1)
	_fill("print(\"Ha\" ____ 3)  # HaHaHa", ["*"], 1, 1)
	_fill("print(\"Hello\", ____)  # Hello World", ["\"World\""], 1, 1)
	_fill("print(\"one\"); ____(\"two\")  # one, then two", ["print"], 1, 1)
	_fill("print(____)  # shows Hi", ["\"Hi\""], 1, 1)
	_fill("print(____)  # shows 3.5", ["3.5"], 1, 1)
	_output("print(\"Hello\")", "Hello", 1, 1)
	_output("print('Python')", "Python", 1, 1)
	_output("print(7)", "7", 1, 1)
	_output("print(\"7\")", "7", 1, 1)
	_output("print(\"Hi\", \"there\")", "Hi there", 1, 1)
	_output("print(\"Hi\" + \"!\")", "Hi!", 1, 1)
	_output("print(\"Ha\" * 3)", "HaHaHa", 1, 1)
	_output("print(\"a\", \"b\", \"c\")", "a b c", 1, 1)
	_output("print(\"Code\" + \"Quest\")", "CodeQuest", 1, 1)
	_output("print(3.5)", "3.5", 1, 1)
	_output("print(\"I am\", 10)", "I am 10", 1, 1)
	_output("print(\"2\" + \"2\")", "22", 1, 1)
	_output("print(\"Python is fun\")", "Python is fun", 1, 1)
	_output("print(\"Hi\", \"Bob\")", "Hi Bob", 1, 1)

	# --- stage 1-2: variables ---
	_fill("x ____ 5  # store 5 in x", ["="], 1, 2)
	_fill("age = 12; print(____)  # 12", ["age"], 1, 2)
	_fill("name = \"Sam\"; print(____)  # Sam", ["name"], 1, 2)
	_fill("x = 3; x = ____; print(x)  # 9", ["9"], 1, 2)
	_fill("a = 2; b = 3; print(a ____ b)  # 5", ["+"], 1, 2)
	_fill("____ = 10; print(score)  # 10", ["score"], 1, 2)
	_fill("city = \"Rome\"; print(city, ____)  # Rome Italy", ["\"Italy\""], 1, 2)
	_fill("n = 4; n = n ____ 1; print(n)  # 5", ["+"], 1, 2)
	_fill("a = 1; b = a; print(____)  # 1", ["b", "a"], 1, 2)
	_fill("pet = \"cat\"; print(\"I have a\", ____)  # I have a cat", ["pet"], 1, 2)
	_fill("x = 10; y = x; y = 20; print(____)  # 10", ["x"], 1, 2)
	_output("x = 5; print(x)", "5", 1, 2)
	_output("name = \"Ann\"; print(name)", "Ann", 1, 2)
	_output("x = 2; x = 7; print(x)", "7", 1, 2)
	_output("a = 3; b = a; print(b)", "3", 1, 2)
	_output("x = 4; print(x, x)", "4 4", 1, 2)
	_output("word = \"hi\"; print(word * 2)", "hihi", 1, 2)
	_output("a = \"Py\"; b = \"thon\"; print(a + b)", "Python", 1, 2)
	_output("x = 1; x = x + 1; print(x)", "2", 1, 2)
	_output("n = 10; print(\"n\")", "n", 1, 2)
	_output("n = 10; print(n)", "10", 1, 2)
	_output("a = 2; b = 3; print(a + b)", "5", 1, 2)
	_output("x = 8; y = x; x = 1; print(y)", "8", 1, 2)
	_output("f = \"A\"; s = \"B\"; print(f, s)", "A B", 1, 2)
	_output("pet = \"cat\"; print(\"my\", pet)", "my cat", 1, 2)
	_output("x = 3.5; print(x)", "3.5", 1, 2)

	# --- stage 1-3: basic arithmetic ---
	_fill("print(4 ____ 2)  # 6", ["+"], 1, 3)
	_fill("print(9 ____ 4)  # 5", ["-"], 1, 3)
	_fill("print(3 ____ 5)  # 15", ["*"], 1, 3)
	_fill("print(8 ____ 2)  # 4.0", ["/"], 1, 3)
	_fill("print(7 ____ 2)  # 3", ["//"], 1, 3)
	_fill("print(7 ____ 2)  # 1", ["%"], 1, 3)
	_fill("print(2 ____ 3)  # 8", ["**"], 1, 3)
	_fill("print(2 + 3 ____ 4)  # 14", ["*"], 1, 3)
	_fill("print((2 + 3) ____ 4)  # 20", ["*"], 1, 3)
	_fill("x = 6; print(x ____ 2)  # 12", ["*"], 1, 3)
	_fill("total = 5 ____ 3; print(total)  # 8", ["+"], 1, 3)
	_fill("print(10 ____ 5)  # 2.0", ["/"], 1, 3)
	_fill("print(____ + 4)  # 10", ["6"], 1, 3)
	_fill("print(20 ____ 6)  # 2", ["%"], 1, 3)
	_output("print(6 + 4)", "10", 1, 3)
	_output("print(10 - 3)", "7", 1, 3)
	_output("print(4 * 5)", "20", 1, 3)
	_output("print(9 / 3)", "3.0", 1, 3)
	_output("print(9 // 2)", "4", 1, 3)
	_output("print(9 % 2)", "1", 1, 3)
	_output("print(3 ** 2)", "9", 1, 3)
	_output("print(2 + 3 * 4)", "14", 1, 3)
	_output("print((2 + 3) * 4)", "20", 1, 3)
	_output("print(10 / 4)", "2.5", 1, 3)
	_output("x = 5; y = 2; print(x * y)", "10", 1, 3)
	_output("a = 8; print(a - 3)", "5", 1, 3)
	_output("print(7 // 2 + 1)", "4", 1, 3)
	_output("print(2 ** 3 + 1)", "9", 1, 3)
	_output("x = 3; x = x * 2; print(x)", "6", 1, 3)
	_output("print(15 % 4)", "3", 1, 3)
	_output("print(100 - 1)", "99", 1, 3)
	_output("print(5 + 5 * 0)", "5", 1, 3)


# ======================================================================
# CHAPTER 2 - printing, variables and arithmetic, one step harder
#   stage 2-1: printing (sep, end, f-strings, str())
#   stage 2-2: variables (swapping, +=, converting types)
#   stage 2-3: arithmetic (order of operations, //, %, **, abs, round, min, max)
# ======================================================================
func _add_chapter_2() -> void:
	# --- stage 2-1: printing, a step further (sep, end, f-strings, str()) ---
	_fill("print(\"a\", \"b\", ____=\"-\")  # a-b", ["sep"], 2, 1)
	_fill("print(\"Hi\", ____=\"!\")  # Hi!", ["end"], 2, 1)
	_fill("print(____\"Hi {1 + 2}\")  # Hi 3", ["f"], 2, 1)
	_fill("name = \"Eve\"; print(f\"Hi, {____}!\")  # Hi, Eve!", ["name"], 2, 1)
	_fill("print(\"Age: \" + ____(12))  # Age: 12", ["str"], 2, 1)
	_fill("print(\"Total:\", 4 ____ 6)  # Total: 10", ["+"], 2, 1)
	_fill("print(\"Hi\", \"Bob\", ____=\"\")  # HiBob", ["sep"], 2, 1)
	_fill("print(____(\"Hello\"))  # 5", ["len"], 2, 1)
	_fill("print(\"hello\".____())  # HELLO", ["upper"], 2, 1)
	_fill("print(\"Go\" ____ 3)  # GoGoGo", ["*"], 2, 1)
	_fill("print(\"x\", \"y\", \"z\", sep=____)  # x-y-z", ["\"-\""], 2, 1)
	_fill("print(\"Hello\".____(\"l\", \"L\"))  # HeLLo", ["replace"], 2, 1)
	_fill("____ = \"Sam\"; print(____\"Hi {name}\")  # Hi Sam", ["name,f"], 2, 1)
	_fill("print(\"a\", \"b\", ____=\"\", ____=\"!\")  # ab!", ["sep,end"], 2, 1)
	_output("print(\"a\", \"b\", sep=\"-\")", "a-b", 2, 1)
	_output("print(\"Hi\", end=\"!\")", "Hi!", 2, 1)
	_output("print(f\"Hi {1 + 2}\")", "Hi 3", 2, 1)
	_output("name = \"Eve\"; print(f\"Hi, {name}!\")", "Hi, Eve!", 2, 1)
	_output("print(\"Age: \" + str(12))", "Age: 12", 2, 1)
	_output("print(\"Total:\", 4 + 6)", "Total: 10", 2, 1)
	_output("print(\"Hi\", \"Bob\", sep=\"\")", "HiBob", 2, 1)
	_output("print(len(\"Hello\"))", "5", 2, 1)
	_output("print(\"hello\".upper())", "HELLO", 2, 1)
	_output("print(\"Go\" * 3)", "GoGoGo", 2, 1)
	_output("print(\"x\", \"y\", \"z\", sep=\"-\")", "x-y-z", 2, 1)
	_output("print(\"Hello\".replace(\"l\", \"L\"))", "HeLLo", 2, 1)
	_output("print(\"Hello\"[1])", "e", 2, 1)
	_output("print(\"Hi\" + \" \" + \"there\")", "Hi there", 2, 1)
	_output("print(f\"{2} + {3}\")", "2 + 3", 2, 1)
	_output("print(f\"{2 + 3}\")", "5", 2, 1)
	_output("print(\"Hi\".lower())", "hi", 2, 1)
	_output("print(\"py\" + str(3))", "py3", 2, 1)
	_output("print(\"5\" * 2)", "55", 2, 1)
	_output("print(len(\"Hi there\"))", "8", 2, 1)
	_output("print(\"Hello\"[-1])", "o", 2, 1)
	_output("print(\"a\", 1, True)", "a 1 True", 2, 1)
	_output("print(\"cat\".title())", "Cat", 2, 1)
	_output("print(\"A-B\".split(\"-\"))", "['A', 'B']", 2, 1)

	# --- stage 2-2: variables, a step further (swapping, +=, converting types) ---
	_fill("a, b = ____; print(a, b)  # 1 2", ["1, 2"], 2, 2)
	_fill("x = 5; x ____ 3; print(x)  # 8", ["+="], 2, 2)
	_fill("x = 10; x ____ 2; print(x)  # 5.0", ["/="], 2, 2)
	_fill("x = 2; x ____ 3; print(x)  # 8", ["**="], 2, 2)
	_fill("x = \"5\"; print(____(x) + 1)  # 6", ["int"], 2, 2)
	_fill("n = 7; print(\"n is \" + ____(n))  # n is 7", ["str"], 2, 2)
	_fill("a = 1; b = 2; a, b = b, ____; print(a, b)  # 2 1", ["a"], 2, 2)
	_fill("x = y = ____; print(x + y)  # 6", ["3"], 2, 2)
	_fill("x = 4; print(____(x))  # <class 'int'>", ["type"], 2, 2)
	_fill("price = 3.5; print(____(price))  # 3", ["int"], 2, 2)
	_fill("word = \"py\"; word ____ \"thon\"; print(word)  # python", ["+="], 2, 2)
	_fill("x = 3; y = x ____ 2; print(y)  # 6", ["*"], 2, 2)
	_fill("a = 1; b = 2; a, b = ____, ____; print(a, b)  # 2 1", ["b,a"], 2, 2)
	_fill("name = \"Ann\"; age = 9; print(name, ____)  # Ann 9", ["age"], 2, 2)
	_output("a, b = 1, 2; print(a, b)", "1 2", 2, 2)
	_output("x = 5; x += 3; print(x)", "8", 2, 2)
	_output("x = 10; x /= 2; print(x)", "5.0", 2, 2)
	_output("x = 2; x **= 3; print(x)", "8", 2, 2)
	_output("x = \"5\"; print(int(x) + 1)", "6", 2, 2)
	_output("n = 7; print(\"n is \" + str(n))", "n is 7", 2, 2)
	_output("a = 1; b = 2; a, b = b, a; print(a, b)", "2 1", 2, 2)
	_output("x = y = 3; print(x + y)", "6", 2, 2)
	_output("x = 4; print(type(x))", "<class 'int'>", 2, 2)
	_output("price = 3.5; print(int(price))", "3", 2, 2)
	_output("word = \"py\"; word += \"thon\"; print(word)", "python", 2, 2)
	_output("x = 3; y = x * 2; print(y)", "6", 2, 2)
	_output("name = \"Ann\"; age = 9; print(name, age)", "Ann 9", 2, 2)
	_output("x = 3.0; print(type(x))", "<class 'float'>", 2, 2)
	_output("x = \"7\"; print(x * 2)", "77", 2, 2)
	_output("x = 7; x -= 2; x *= 3; print(x)", "15", 2, 2)
	_output("a = 5; b = 2; print(a // b, a % b)", "2 1", 2, 2)
	_output("x = 5; y = x; x += 1; print(y)", "5", 2, 2)
	_output("s = \"ab\"; print(s * 2, len(s))", "abab 2", 2, 2)
	_output("x = int(\"4\") + int(\"6\"); print(x)", "10", 2, 2)

	# --- stage 2-3: arithmetic, a step further (order of operations, //, %, **, abs, round, min, max) ---
	_fill("print(2 + 3 ____ 4 - 1)  # 13", ["*"], 2, 3)
	_fill("print((8 - 2) ____ 4)  # 1", ["//"], 2, 3)
	_fill("print(17 ____ 5 * 2)  # 4", ["%"], 2, 3)
	_fill("x = 10; x ____ 5; print(x)  # 15", ["+="], 2, 3)
	_fill("x = 10; x ____ 5; print(x)  # 50", ["*="], 2, 3)
	_fill("print(abs(-7) ____ 2)  # 9", ["+"], 2, 3)
	_fill("print(round(2.6) ____ 1)  # 4", ["+"], 2, 3)
	_fill("print(7 ____ 2)  # 3.5", ["/"], 2, 3)
	_fill("print(____(7 / 2))  # 3", ["int"], 2, 3)
	_fill("print(10 // 3 * 3 ____ 10 % 3)  # 10", ["+"], 2, 3)
	_fill("print(2 ____ 4)  # 16", ["**"], 2, 3)
	_fill("print(____(3, 8, 5))  # 8", ["max"], 2, 3)
	_fill("print(____(3, 8, 5))  # 3", ["min"], 2, 3)
	_fill("print(____(10, 3))  # (3, 1)", ["divmod"], 2, 3)
	_fill("print(5 + ____ * 2)  # 11", ["3"], 2, 3)
	_fill("print(____ ** 2)  # 49", ["7"], 2, 3)
	_fill("print(____(-3) ____ 2)  # 5", ["abs,+"], 2, 3)
	_fill("x = 4; x ____ 2; x ____ 3; print(x)  # 18", ["+=,*="], 2, 3)
	_output("print(2 + 3 * 4 - 1)", "13", 2, 3)
	_output("print((8 - 2) // 4)", "1", 2, 3)
	_output("print(17 % 5 * 2)", "4", 2, 3)
	_output("x = 10; x += 5; print(x)", "15", 2, 3)
	_output("x = 10; x *= 5; print(x)", "50", 2, 3)
	_output("print(abs(-7) + 2)", "9", 2, 3)
	_output("print(round(2.6) + 1)", "4", 2, 3)
	_output("print(7 / 2)", "3.5", 2, 3)
	_output("print(int(7 / 2))", "3", 2, 3)
	_output("print(10 // 3 * 3 + 10 % 3)", "10", 2, 3)
	_output("print(2 ** 5)", "32", 2, 3)
	_output("print(max(3, 8, 5))", "8", 2, 3)
	_output("print(min(3, 8, 5))", "3", 2, 3)
	_output("print(divmod(10, 3))", "(3, 1)", 2, 3)
	_output("print(5 + 3 * 2)", "11", 2, 3)
	_output("print(-7 ** 2)", "-49", 2, 3)
	_output("print(2 + 2 * 2 ** 2)", "10", 2, 3)
	_output("x = 4; x += 2; x *= 3; print(x)", "18", 2, 3)
	_output("print(100 // 7)", "14", 2, 3)
	_output("print(100 % 7)", "2", 2, 3)
	_output("print(round(3.14159, 2))", "3.14", 2, 3)
	_output("print(9 ** 0.5)", "3.0", 2, 3)
	_output("print(abs(3 - 10))", "7", 2, 3)
	_output("print((2 + 3) * (4 - 1))", "15", 2, 3)
	_output("print(10 - 4 - 3)", "3", 2, 3)
	_output("print(2 * 3 ** 2)", "18", 2, 3)


# ======================================================================
# CHAPTER 3 - simple loops
#   stage 3-1: for loops and range
#   stage 3-2: while loops
#   stage 3-3: break, continue and running totals
# These snippets can be several lines: "\n" starts a new line, and the blanks of a
# fill-in are answered in reading order (top to bottom, left to right).
# Loops print with end=" " so every answer fits on one line, e.g. "0 1 2".
# ======================================================================
func _add_chapter_3() -> void:
	# --- stage 3-1: for loops and range ---
	_fill("for i in ____(3): print(i, end=\" \")  # 0 1 2", ["range"], 3, 1)
	_fill("for i in range(____): print(i, end=\" \")  # 0 1 2 3", ["4"], 3, 1)
	_fill("for i in range(1, ____): print(i, end=\" \")  # 1 2 3", ["4"], 3, 1)
	_fill("for i in range(0, 10, ____): print(i, end=\" \")  # 0 5", ["5"], 3, 1)
	_fill("for i in range(5, 0, ____): print(i, end=\" \")  # 5 4 3 2 1", ["-1"], 3, 1)
	_fill("for ch in \"abc\": print(____, end=\"\")  # abc", ["ch"], 3, 1)
	_fill("for n in [2, 4, 6]: print(n ____ 2, end=\" \")  # 4 8 12", ["*"], 3, 1)
	_fill("total = 0\nfor i in range(1, 5): total ____ i\nprint(total)  # 10", ["+="], 3, 1)
	_fill("____ i in range(3): print(i, end=\" \")  # 0 1 2", ["for"], 3, 1)
	_fill("count = 0\nfor i in range(6): count ____ 1\nprint(count)  # 6", ["+="], 3, 1)
	_fill("____ i in ____(3): print(i, end=\" \")  # 0 1 2", ["for,range"], 3, 1)
	_fill("for i in range(1, 4): print(\"*\" ____ i, end=\" \")  # * ** ***", ["*"], 3, 1)
	_fill("word = \"\"\nfor ch in \"abc\": word ____ ch\nprint(word)  # abc", ["+="], 3, 1)
	_fill("for i in range(2, 7, ____): print(i, end=\" \")  # 2 4 6", ["2"], 3, 1)
	_output("for i in range(3): print(i, end=\" \")", "0 1 2", 3, 1)
	_output("for i in range(1, 4): print(i, end=\" \")", "1 2 3", 3, 1)
	_output("for i in range(0, 10, 5): print(i, end=\" \")", "0 5", 3, 1)
	_output("for i in range(5, 0, -1): print(i, end=\" \")", "5 4 3 2 1", 3, 1)
	_output("for ch in \"abc\": print(ch, end=\"\")", "abc", 3, 1)
	_output("for n in [2, 4, 6]: print(n * 2, end=\" \")", "4 8 12", 3, 1)
	_output("total = 0\nfor i in range(1, 5): total += i\nprint(total)", "10", 3, 1)
	_output("count = 0\nfor i in range(6): count += 1\nprint(count)", "6", 3, 1)
	_output("for i in range(2): print(\"Hi\", end=\" \")", "Hi Hi", 3, 1)
	_output("word = \"\"\nfor ch in \"abc\": word += ch\nprint(word)", "abc", 3, 1)
	_output("for i in range(3): print(i * i, end=\" \")", "0 1 4", 3, 1)
	_output("for i in range(4): print(i + 1, end=\" \")", "1 2 3 4", 3, 1)
	_output("for c in \"hey\": print(c.upper(), end=\"\")", "HEY", 3, 1)
	_output("total = 0\nfor n in [3, 4, 5]: total += n\nprint(total)", "12", 3, 1)
	_output("for i in range(3, 6): print(i, end=\" \")", "3 4 5", 3, 1)
	_output("for i in range(10, 0, -3): print(i, end=\" \")", "10 7 4 1", 3, 1)

	# --- stage 3-2: while loops ---
	_fill("i = 0\n____ i < 3: print(i, end=\" \"); i += 1  # 0 1 2", ["while"], 3, 2)
	_fill("i = 0\nwhile i < ____: print(i, end=\" \"); i += 1  # 0 1 2 3", ["4"], 3, 2)
	_fill("i = 0\nwhile i < 3: print(i, end=\" \"); i ____ 1  # 0 1 2", ["+="], 3, 2)
	_fill("n = 3\nwhile n ____ 0: print(n, end=\" \"); n -= 1  # 3 2 1", [">", "!="], 3, 2)
	_fill("n = 3\nwhile n > 0: print(n, end=\" \"); n ____ 1  # 3 2 1", ["-="], 3, 2)
	_fill("total = 0; i = 1\nwhile i <= 4: total += i; i ____ 1\nprint(total)  # 10", ["+="], 3, 2)
	_fill("x = 1\nwhile x < 20: x ____ 2\nprint(x)  # 32", ["*="], 3, 2)
	_fill("i = 0\nwhile True:\n    i += 1\n    if i == 3: ____\nprint(i)  # 3", ["break"], 3, 2)
	_fill("count = 0\nwhile count < 5: count += 1\nprint(____)  # 5", ["count"], 3, 2)
	_fill("i = 0\n____ i < 3: print(i, end=\" \"); i ____ 1  # 0 1 2", ["while,+="], 3, 2)
	_fill("n = 10\nwhile n > 5: n ____ 2\nprint(n)  # 4", ["-="], 3, 2)
	_fill("s = \"\"; i = 0\nwhile i < 3: s += \"a\"; i ____ 1\nprint(s)  # aaa", ["+="], 3, 2)
	_fill("i = 0\nwhile i < 6: print(i, end=\" \"); i += ____  # 0 2 4", ["2"], 3, 2)
	_output("i = 0\nwhile i < 3: print(i, end=\" \"); i += 1", "0 1 2", 3, 2)
	_output("n = 3\nwhile n > 0: print(n, end=\" \"); n -= 1", "3 2 1", 3, 2)
	_output("total = 0; i = 1\nwhile i <= 4: total += i; i += 1\nprint(total)", "10", 3, 2)
	_output("x = 1\nwhile x < 20: x *= 2\nprint(x)", "32", 3, 2)
	_output("i = 0\nwhile True:\n    i += 1\n    if i == 3: break\nprint(i)", "3", 3, 2)
	_output("n = 10\nwhile n > 5: n -= 2\nprint(n)", "4", 3, 2)
	_output("s = \"\"; i = 0\nwhile i < 3: s += \"a\"; i += 1\nprint(s)", "aaa", 3, 2)
	_output("i = 0\nwhile i < 6: print(i, end=\" \"); i += 2", "0 2 4", 3, 2)
	_output("count = 0\nwhile count < 5: count += 1\nprint(count)", "5", 3, 2)
	_output("i = 5\nwhile i < 3: i += 1\nprint(i)", "5", 3, 2)
	_output("n = 1\nwhile n < 100: n *= 3\nprint(n)", "243", 3, 2)
	_output("i = 0\nwhile i < 3: i += 1\nprint(i * 2)", "6", 3, 2)
	_output("total = 0; n = 5\nwhile n > 0: total += n; n -= 1\nprint(total)", "15", 3, 2)
	_output("i = 10\nwhile i > 0: i -= 4\nprint(i)", "-2", 3, 2)

	# --- stage 3-3: break, continue and running totals ---
	_fill("for i in range(5):\n    if i == 3: ____\n    print(i, end=\" \")  # 0 1 2", ["break"], 3, 3)
	_fill("for i in range(5):\n    if i == 2: ____\n    print(i, end=\" \")  # 0 1 3 4", ["continue"], 3, 3)
	_fill("for i in range(5):\n    if i % 2 ____ 0: continue\n    print(i, end=\" \")  # 1 3", ["=="], 3, 3)
	_fill("total = 0\nfor n in [1, 2, 3, 4]:\n    if n % 2 == 0: total ____ n\nprint(total)  # 6", ["+="], 3, 3)
	_fill("count = 0\nfor ch in \"banana\":\n    if ch == \"a\": count ____ 1\nprint(count)  # 3", ["+="], 3, 3)
	_fill("for n in [4, 7, 9]:\n    if n > 5: ____\nprint(n)  # 7", ["break"], 3, 3)
	_fill("biggest = 0\nfor n in [3, 9, 4]:\n    if n > biggest: biggest = ____\nprint(biggest)  # 9", ["n"], 3, 3)
	_fill("word = \"\"\nfor ch in \"hello\":\n    if ch ____ \"l\": word += ch\nprint(word)  # ll", ["=="], 3, 3)
	_fill("total = 0\nfor i in range(1, ____): total += i\nprint(total)  # 6", ["4"], 3, 3)
	_fill("for i in range(10):\n    if i > 2: ____\nprint(i)  # 3", ["break"], 3, 3)
	_fill("total = 0\n____ n in [1, 2, 3]: total ____ n\nprint(total)  # 6", ["for,+="], 3, 3)
	_fill("evens = 0\nfor n in range(1, 7):\n    if n % 2 == 0: evens ____ 1\nprint(evens)  # 3", ["+="], 3, 3)
	_fill("for name in [\"Al\", \"Bo\"]:\n    print(\"Hi \" + ____, end=\" \")  # Hi Al Hi Bo", ["name"], 3, 3)
	_output("for i in range(5):\n    if i == 3: break\n    print(i, end=\" \")", "0 1 2", 3, 3)
	_output("for i in range(5):\n    if i == 2: continue\n    print(i, end=\" \")", "0 1 3 4", 3, 3)
	_output("for i in range(5):\n    if i % 2 == 0: continue\n    print(i, end=\" \")", "1 3", 3, 3)
	_output("total = 0\nfor n in [1, 2, 3, 4]:\n    if n % 2 == 0: total += n\nprint(total)", "6", 3, 3)
	_output("count = 0\nfor ch in \"banana\":\n    if ch == \"a\": count += 1\nprint(count)", "3", 3, 3)
	_output("for n in [4, 7, 9]:\n    if n > 5: break\nprint(n)", "7", 3, 3)
	_output("biggest = 0\nfor n in [3, 9, 4]:\n    if n > biggest: biggest = n\nprint(biggest)", "9", 3, 3)
	_output("word = \"\"\nfor ch in \"hello\":\n    if ch == \"l\": word += ch\nprint(word)", "ll", 3, 3)
	_output("total = 0\nfor i in range(1, 4): total += i\nprint(total)", "6", 3, 3)
	_output("for i in range(10):\n    if i > 2: break\nprint(i)", "3", 3, 3)
	_output("evens = 0\nfor n in range(1, 7):\n    if n % 2 == 0: evens += 1\nprint(evens)", "3", 3, 3)
	_output("for name in [\"Al\", \"Bo\"]:\n    print(\"Hi \" + name, end=\" \")", "Hi Al Hi Bo", 3, 3)
	_output("total = 0\nfor n in [5, 10, 15]:\n    if n > 7: total += n\nprint(total)", "25", 3, 3)
	_output("for i in range(4):\n    if i == 1: continue\n    if i == 3: break\n    print(i, end=\" \")", "0 2", 3, 3)
	_output("total = 1\nfor i in range(1, 5): total *= i\nprint(total)", "24", 3, 3)


# Mixed-difficulty set. Chapters whose own challenges are not written yet fall back to this.
func _add_general_challenges() -> void:
	# --- fill in the missing part ---
	_fill("for i in ____(3): print(i)  # 0 1 2", ["range"])
	_fill("print(____([4, 1, 7]))  # 12", ["sum"])
	_fill("print(____(\"python\"))  # 6", ["len"])
	_fill("x = ____(input())  # a whole number", ["int"])
	_fill("print(\"hi\".____())  # HI", ["upper"])
	_fill("print(\"A,B\".____(\",\"))  # ['A', 'B']", ["split"])
	_fill("n = [1]; n.____(2)  # [1, 2]", ["append"])
	_fill("____ 5 > 3: print(\"yes\")  # runs once", ["if"])
	_fill("____ add(a, b): return a + b", ["def"])
	_fill("sq = ____ x: x * x", ["lambda"])
	_fill("____ math  # lets us use math.pi", ["import"])
	_fill("print(10 ____ 3)  # 1", ["%"])
	_fill("print(2 ____ 3)  # 8", ["**"])
	_fill("print(\"ab\" ____ 2)  # abab", ["*"])
	_fill("print(type(5) == ____)  # True", ["int"])
	_fill("print(____(\"b\", \"a\"))  # a", ["min"])
	_fill("print(\"hello\"[____])  # e", ["1", "-4"])
	# two blanks: answer with both parts, separated by a comma
	_fill("____ x in [1, 2]: ____(x)  # prints 1 2", ["for,print"])
	_fill("____ add(a, b): ____ a + b", ["def,return"])
	_fill("____ 5 > 3: ____(\"big\")", ["if,print"])

	# --- type the output ---
	_output("print(2 + 3)", "5")
	_output("print(\"py\" * 3)", "pypypy")
	_output("print(len(\"code\"))", "4")
	_output("print(10 // 3)", "3")
	_output("print(10 % 3)", "1")
	_output("print(2 ** 4)", "16")
	_output("print(\"Hi\".upper())", "HI")
	_output("print(\"a\" + \"b\")", "ab")
	_output("print([1, 2, 3][1])", "2")
	_output("print(max(3, 9, 4))", "9")
	_output("print(7 > 3)", "True")
	_output("print(not True)", "False")
	_output("print(\"hello\"[0])", "h")
	_output("print(sum([1, 2, 3]))", "6")
	_output("print(\"a,b\".split(\",\"))", "['a', 'b']")
	_output("print(int(\"5\") + 1)", "6")
	_output("print(5 / 2)", "2.5")
	_output("print(\"abc\".replace(\"b\", \"x\"))", "axc")
	_output("print(list(range(3)))", "[0, 1, 2]")
	_output("print(abs(-4))", "4")
	_output("print(round(3.7))", "4")
	_output("print(type(1))", "<class 'int'>")
	_output("print(3 == 3.0)", "True")
	_output("print(\"b\" in \"abc\")", "True")
	_output("print(bool(0))", "False")
	_output("x = 4; print(x * x)", "16")
	_output("print(min([5, 2, 8]))", "2")
	_output("print(10 - 2 * 3)", "4")
	_output("print(\"Py\"[::-1])", "yP")
	_output("print(len(str(100)))", "3")
	_output("print(str(1) + str(2))", "12")
