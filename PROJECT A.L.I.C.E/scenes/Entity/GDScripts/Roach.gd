extends Sprite
class_name Roach
# Roach enemy: it ONLY asks "fill in the blank" challenges.
# It scurries in a straight line toward the player. Player.gd removes it when it reaches her.

# Which kind of challenge this enemy asks. main.gd reads this when it spawns the enemy.
var challenge_kind: String = "fill"


# ---------------------------------------------------------------
# Properties (editable in the inspector)
# ---------------------------------------------------------------
export (Color) var tag_color = Color("#6a9955")          # the small caption
export (Color) var code_color = Color("#d4d4d4")         # the code itself
export (Color) var blank_color = Color("#e5c07b")        # the ____ blanks
export (Color) var background_color = Color(0.05, 0.05, 0.05, 0.9)
export (float) var prompt_width = 440.0     # minimum box width; it grows by itself if the text needs more room
export (float) var prompt_offset_y = -16.0   # moves the box relative to the sprite (negative = up)
export (float) var bottom_reserved = 132.0   # screen space kept free at the bottom for the typing box
export (float) var font_scale = 0.75      # 1.0 = normal size, smaller = smaller text (and box)
export (Font) var prompt_font             # optional: a DynamicFont gives the crispest small text (then use font_scale 1)

export (float) var speed = 30.0
export (float) var bottom_offset = 80.0

var _challenge = null
var _target_position: Vector2 = Vector2.ZERO
var _prompt_size: Vector2 = Vector2.ZERO
var _font = null
var _line_height: float = 0.0

onready var _prompt_label = $RichTextLabel


# ---------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------
func _ready() -> void:
	var screen = get_viewport_rect().size
	_target_position = Vector2(screen.x / 2, screen.y - bottom_offset)
	_setup_prompt_label()


func _process(delta: float) -> void:
	_move(delta)
	_update_prompt_position()


# ---------------------------------------------------------------
# Public interface (used by main.gd)
# ---------------------------------------------------------------
func set_challenge(challenge) -> void:
	_challenge = challenge
	_render_prompt()


func check_answer(answer: String) -> bool:
	return _challenge != null and _challenge.is_correct(answer)


func defeat() -> void:
	queue_free()


func get_distance_to_target() -> float:
	return position.distance_to(_target_position)


func has_arrived() -> bool:
	return position.distance_to(_target_position) < 0.5


# ---------------------------------------------------------------
# Movement: a straight line to the target
# ---------------------------------------------------------------
func _move(delta: float) -> void:
	position = position.move_toward(_target_position, speed * delta)


# ---------------------------------------------------------------
# Prompt display
# ---------------------------------------------------------------
func _setup_prompt_label() -> void:
	_prompt_label.scroll_active = false
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# dark "terminal" background so the code is easy to read
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = Color("#4b5563")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_prompt_label.add_stylebox_override("normal", style)

	var font = _prompt_label.get_font("normal_font")
	if prompt_font != null:
		font = prompt_font
		_prompt_label.add_font_override("normal_font", prompt_font)

	# two lines of text (caption + code) plus the margins
	_font = font
	_line_height = font.get_height() + _prompt_label.get_constant("line_separation")
	_prompt_label.rect_size = Vector2(prompt_width, _line_height * 2.0 + 16.0)

	# font_scale shrinks the whole label; dividing by the sprite's scale keeps it
	# the same size even if the sprite itself is scaled
	var gs = get_global_transform().get_scale()
	_prompt_label.rect_scale = Vector2(
		font_scale / max(abs(gs.x), 0.001),
		font_scale / max(abs(gs.y), 0.001)
	)

	# size on screen, used to position the label
	_prompt_size = _prompt_label.rect_size * font_scale


func _render_prompt() -> void:
	_prompt_label.clear()
	_add_text(_challenge.get_instruction(), tag_color)
	_prompt_label.newline()

	# Drawn piece by piece (not as BBCode) so characters like [ ] in code are safe.
	var parts = _challenge.get_display_code().split("____")
	for i in range(parts.size()):
		_add_text(parts[i], code_color)
		if i < parts.size() - 1:
			_add_text("____", blank_color)

	_fit_prompt_box()


# Makes the box wide enough for the longest line, so bigger fonts never wrap or get cut off.
func _fit_prompt_box() -> void:
	var caption_width = _font.get_string_size(_challenge.get_instruction()).x
	var code_width = _font.get_string_size(_challenge.get_display_code()).x
	var needed = max(caption_width, code_width) + 16.0 + 6.0   # side margins + a little slack
	_prompt_label.rect_size = Vector2(max(prompt_width, needed), _line_height * 2.0 + 16.0)
	_prompt_size = _prompt_label.rect_size * font_scale


func _add_text(text: String, color: Color) -> void:
	if text == "":
		return
	_prompt_label.push_color(color)
	_prompt_label.add_text(text)
	_prompt_label.pop()


# Sits just below the enemy and stays on screen, above the typing box.
func _update_prompt_position() -> void:
	var half_height = 16.0
	if texture != null:
		var gs = get_global_transform().get_scale()
		half_height = texture.get_height() / float(max(vframes, 1)) * abs(gs.y) / 2.0

	var desired = global_position + Vector2(-_prompt_size.x / 2.0, half_height + 8.0 + prompt_offset_y)
	var screen = get_viewport_rect().size
	desired.x = clamp(desired.x, 0.0, max(screen.x - _prompt_size.x, 0.0))
	desired.y = clamp(desired.y, 0.0, max(screen.y - bottom_reserved - _prompt_size.y, 0.0))
	_prompt_label.set_global_position(desired)
