extends Sprite
class_name Enemy
# Base class for every enemy. Shared behaviour lives here;
# subclasses (Roach, Butterfly) customise it by overriding methods.


# ---------------------------------------------------------------
# Helper class: builds the coloured BBCode string for a prompt.
# Enemy *owns* a PromptFormatter object (composition).
# ---------------------------------------------------------------
class PromptFormatter:
	var typed_color: Color
	var current_color: Color
	var remaining_color: Color

	func _init(typed: Color, current: Color, remaining: Color):
		typed_color = typed
		current_color = current
		remaining_color = remaining

	func format(text: String, index: int) -> String:
		var typed = _colorize(typed_color, text.substr(0, index))
		var current = _colorize(current_color, text.substr(index, 1))
		var remaining = _colorize(remaining_color, text.substr(index + 1, text.length()))
		return "[center]" + typed + current + remaining + "[/center]"

	func _colorize(color: Color, text: String) -> String:
		return "[color=#" + color.to_html(false) + "]" + text + "[/color]"


# ---------------------------------------------------------------
# Properties (editable in the inspector)
# ---------------------------------------------------------------
export (Color) var blue = Color("#4682b4")   # letters already typed
export (Color) var red = Color("#a65455")    # letters still to type
export (Color) var green = Color("#639765")  # the next letter to type

export (float) var speed = 50.0
export (float) var bottom_offset = 80.0

# "Private" state (underscore = only use inside this class / subclasses)
var _prompt_text: String = ""
var _target_position: Vector2 = Vector2.ZERO
var _formatter: PromptFormatter = null

onready var _prompt_label = $RichTextLabel


# ---------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------
func _ready() -> void:
	_prompt_text = _prompt_label.text
	var screen = get_viewport_rect().size
	_target_position = Vector2(screen.x / 2, screen.y - bottom_offset)
	_formatter = PromptFormatter.new(blue, green, red)


func _process(delta: float) -> void:
	_move(delta)   # subclasses change behaviour by overriding _move()


# ---------------------------------------------------------------
# Public interface (used by main.gd and Player.gd)
# ---------------------------------------------------------------
func get_prompt() -> String:
	return _prompt_text


func next_character(index: int) -> void:
	_prompt_label.parse_bbcode(_formatter.format(_prompt_text, index))


func has_arrived() -> bool:
	return position.distance_to(_target_position) < 0.5


# ---------------------------------------------------------------
# Overridable behaviour
# ---------------------------------------------------------------
func _move(delta: float) -> void:
	position = position.move_toward(_target_position, speed * delta)
