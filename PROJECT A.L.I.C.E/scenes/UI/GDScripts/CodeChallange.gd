extends Resource
class_name CodeChallenge
# One line of code shown by an enemy.
#   FILL   - part of the line is missing ("____"); the player types the missing part.
#            A line with 2+ blanks is answered with the parts separated by commas.
#   OUTPUT - the line is complete; the player types what it prints.

const FILL = "fill"
const OUTPUT = "output"

var kind: String
var code: String
var answers: Array


func _init(p_kind: String, p_code: String, p_answers: Array):
	kind = p_kind
	code = p_code
	answers = p_answers


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
