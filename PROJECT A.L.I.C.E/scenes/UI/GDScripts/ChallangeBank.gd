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

	# The text shown to the player. Output lines get a Python prompt in front.
	func get_display_code() -> String:
		if kind == OUTPUT:
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
# Chapters 2-5 go here as _add_chapter_2() ... once they are written.
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
