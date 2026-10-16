extends Sprite
class_name Butterfly
# Butterfly enemy: it ONLY asks "what does this print?" (output) challenges.
# It flutters from side to side while heading to the player. Player.gd removes it when it reaches her.

# Which kind of challenge this enemy asks. main.gd reads this when it spawns the enemy.
var challenge_kind: String = "output"


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

export (float) var speed = 20.0
export (float) var bottom_offset = 80.0
export (float) var sway_amount = 120.0
export (float) var sway_speed = 3.0

var _challenge = null
var _target_position: Vector2 = Vector2.ZERO
var _prompt_size: Vector2 = Vector2.ZERO
var _font = null
var _line_height: float = 0.0

# The flutter is added on top of a straight-line "base" position, so the code box
# can follow the base and stay still while only the sprite sways.
var _base_position: Vector2 = Vector2.ZERO
var _base_ready: bool = false
var _time: float = 0.0
var _sway_x: float = 0.0

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
	var origin = _base_position if _base_ready else position
	return origin.distance_to(_target_position)


func has_arrived() -> bool:
	var origin = _base_position if _base_ready else position
	return origin.distance_to(_target_position) < 0.5


# ---------------------------------------------------------------
# Movement: straight line to the target plus a side-to-side flutter
# ---------------------------------------------------------------
func _move(delta: float) -> void:
	if not _base_ready:
		# main.gd sets the spawn position after _ready(), so start from it here
		_base_position = position
		_base_ready = true

	_base_position = _base_position.move_toward(_target_position, speed * delta)
	_time += delta
	_sway_x = sin(_time * sway_speed) * (sway_amount / max(sway_speed, 0.001))
	position = _base_position + Vector2(_sway_x, 0.0)


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

	var anchor = global_position - Vector2(_sway_x, 0.0)   # the sprite without its sway
	var desired = anchor + Vector2(-_prompt_size.x / 2.0, half_height + 8.0 + prompt_offset_y)
	var screen = get_viewport_rect().size
	desired.x = clamp(desired.x, 0.0, max(screen.x - _prompt_size.x, 0.0))
	desired.y = clamp(desired.y, 0.0, max(screen.y - bottom_reserved - _prompt_size.y, 0.0))
	_prompt_label.set_global_position(desired)
