extends AnimatedSprite
# Enemy3 (bee): it asks either kind of challenge (fill in the blank or output).
# It buzzes toward the player with a quick, small zigzag.
# Animations (from the SpriteFrames): "approach" while it walks, "attack" when it reaches
# the player (it disappears after the attack animation), "death" when the player solves
# its code challenge (it disappears after the death animation).

# Which kind of challenge this enemy asks: "fill", "output", or "" for either kind.
# main.gd reads this when it spawns the enemy.
export var challenge_kind: String = ""

enum State { APPROACH, ATTACKING, DYING }


# ---------------------------------------------------------------
# Properties (editable in the inspector)
# ---------------------------------------------------------------
export (String) var approach_animation = "approach"
export (String) var attack_animation = "attack"
export (String) var death_animation = "death"
export (float) var exit_hold = 0.1   # extra time the last frame stays before the enemy disappears

export (Color) var tag_color = Color("#6a9955")          # the small caption
export (Color) var code_color = Color("#d4d4d4")         # the code itself
export (Color) var blank_color = Color("#e5c07b")        # the ____ blanks
export (Color) var background_color = Color(0.05, 0.05, 0.05, 0.9)
export (Color) var target_color = Color("#facc15")   # the target marker and the target's code box border
export (float) var prompt_width = 440.0     # minimum box width; it grows by itself if the text needs more room
export (float) var prompt_offset_y = -16.0   # moves the box relative to the sprite (negative = up)
export (float) var bottom_reserved = 132.0   # screen space kept free at the bottom for the typing box
export (float) var font_scale = 0.75      # 1.0 = normal size, smaller = smaller text (and box)
export (Font) var prompt_font             # optional: a DynamicFont gives the crispest small text (then use font_scale 1)

export (float) var speed = 20.0
export (float) var bottom_offset = 80.0
export (float) var sway_amount = 90.0
export (float) var sway_speed = 6.0

var _challenge = null
var _target_position: Vector2 = Vector2.ZERO
var _prompt_size: Vector2 = Vector2.ZERO
var _font = null
var _line_height: float = 0.0
var _state = State.APPROACH
var _state_time: float = 0.0
var _exit_time: float = 0.0
var _targeted: bool = false
var _target_pulse: float = 0.0
var _prompt_style = null

# The sway is added on top of a straight-line "base" position.
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
	_play(approach_animation)   # every enemy starts by approaching


func _process(delta: float) -> void:
	if _state == State.APPROACH:
		_move(delta)
		_update_prompt_position()
		if _targeted:
			_target_pulse += delta
			update()   # redraw the pulsing target marker
	else:
		# attacking or dying: wait for the animation to finish, then disappear
		_state_time += delta
		if _state_time >= _exit_time:
			set_process(false)
			queue_free()


# ---------------------------------------------------------------
# Public interface (used by main.gd and Player.gd)
# ---------------------------------------------------------------
func set_challenge(challenge) -> void:
	_challenge = challenge
	_render_prompt()


# False once the enemy is attacking or dying: it can no longer be answered or hit.
func can_be_hit() -> bool:
	return _state == State.APPROACH and not is_queued_for_deletion()


func check_answer(answer: String) -> bool:
	return can_be_hit() and _challenge != null and _challenge.is_correct(answer)


# The player solved the challenge: play the death animation, then disappear.
func defeat() -> void:
	_start_exit(State.DYING, death_animation)


# The enemy reached the player: play the attack animation, then disappear.
# Player.gd calls this when the enemy touches her hurtbox.
func attack() -> void:
	_start_exit(State.ATTACKING, attack_animation)


# The player's current target: a pulsing marker around the sprite and a bright code box.
func set_targeted(value: bool) -> void:
	if value and not can_be_hit():
		return
	_targeted = value
	_target_pulse = 0.0
	_apply_target_style()
	update()   # redraw the marker


func is_targeted() -> bool:
	return _targeted


func _apply_target_style() -> void:
	if _prompt_style == null:
		return
	if _targeted:
		_prompt_style.border_color = target_color
		_prompt_style.set_border_width_all(3)
	else:
		_prompt_style.border_color = Color("#4b5563")
		_prompt_style.set_border_width_all(1)


# Corner brackets around the sprite that gently pulse. Only the target gets them.
func _draw() -> void:
	if not _targeted:
		return
	var half = Vector2(24, 24)
	var center = offset
	if frames != null and frames.has_animation(animation):
		var frame_texture = frames.get_frame(animation, frame)
		if frame_texture != null:
			half = frame_texture.get_size() / 2.0
			if not centered:
				center += half
	var gs = get_global_transform().get_scale()
	var inv = Vector2(1.0 / max(abs(gs.x), 0.001), 1.0 / max(abs(gs.y), 0.001))   # keeps the lines the same size on screen
	var pad = 6.0 + 3.0 * (0.5 + 0.5 * sin(_target_pulse * 6.0))
	var box = half + Vector2(pad, pad) * inv
	var arm = min(box.x, box.y) * 0.45
	var width = 3.0 * inv.x
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var c = center + Vector2(box.x * corner.x, box.y * corner.y)
		draw_line(c, c + Vector2(-corner.x * arm, 0), target_color, width)
		draw_line(c, c + Vector2(0, -corner.y * arm), target_color, width)


func get_distance_to_target() -> float:
	var origin = _base_position if _base_ready else position
	return origin.distance_to(_target_position)


# ---------------------------------------------------------------
# Movement
# ---------------------------------------------------------------
# a straight line to the target plus a side-to-side sway
func _move(delta: float) -> void:
	if not _base_ready:
		# main.gd sets the spawn position after _ready(), so start from it here
		_base_position = position
		_base_ready = true

	_base_position = _base_position.move_toward(_target_position, speed * delta)
	_time += delta
	_sway_x = sin(_time * sway_speed) * (sway_amount / max(sway_speed, 0.001))
	position = _base_position + Vector2(_sway_x, 0.0)


# the code box follows the base position, so only the sprite sways and the text stays still
func _prompt_anchor() -> Vector2:
	return global_position - Vector2(_sway_x, 0.0)


# ---------------------------------------------------------------
# Animations
# ---------------------------------------------------------------
func _start_exit(new_state, animation_name: String) -> void:
	if not can_be_hit():
		return
	set_targeted(false)   # an enemy that is attacking or dying is no longer a target
	_state = new_state
	_state_time = 0.0
	_prompt_label.hide()   # the code box goes away with the challenge
	_play(animation_name)
	_exit_time = _animation_length(animation_name) + exit_hold


func _play(animation_name: String) -> void:
	if frames == null or not frames.has_animation(animation_name):
		push_warning("%s: there is no animation called '%s'" % [name, animation_name])
		return
	if animation_name != approach_animation:
		frames.set_animation_loop(animation_name, false)   # attack and death play once
	play(animation_name)


# How long an animation takes, so the enemy can disappear right when it ends.
func _animation_length(animation_name: String) -> float:
	if frames == null or not frames.has_animation(animation_name):
		return 0.0
	var fps = frames.get_animation_speed(animation_name)
	if fps <= 0.0:
		return 0.0
	return float(frames.get_frame_count(animation_name)) / fps / max(abs(speed_scale), 0.001)


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
	_prompt_style = style   # kept so the box can light up when this enemy is the target

	var font = _prompt_label.get_font("normal_font")
	if prompt_font != null:
		font = prompt_font
		_prompt_label.add_font_override("normal_font", prompt_font)

	# starts as two lines (caption + code); _fit_prompt_box() resizes it for each challenge
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
	# A challenge can be several lines: one text line each.
	var code_lines = _challenge.get_display_code().split("\n")
	for n in range(code_lines.size()):
		var parts = code_lines[n].split("____")
		for i in range(parts.size()):
			_add_text(parts[i], code_color)
			if i < parts.size() - 1:
				_add_text("____", blank_color)
		if n < code_lines.size() - 1:
			_prompt_label.newline()

	_fit_prompt_box()


# Makes the box wide enough for the longest line and tall enough for every line,
# so bigger fonts and longer snippets never wrap or get cut off.
func _fit_prompt_box() -> void:
	var code_lines = _challenge.get_display_code().split("\n")
	var widest = _font.get_string_size(_challenge.get_instruction()).x
	for code_line in code_lines:
		widest = max(widest, _font.get_string_size(code_line).x)
	var needed = widest + 16.0 + 6.0   # side margins + a little slack
	var text_lines = 1 + code_lines.size()   # the caption + the code
	_prompt_label.rect_size = Vector2(max(prompt_width, needed), _line_height * text_lines + 16.0)
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
	if frames != null and frames.has_animation(animation):
		var frame_texture = frames.get_frame(animation, frame)
		if frame_texture != null:
			var gs = get_global_transform().get_scale()
			half_height = frame_texture.get_height() * abs(gs.y) / 2.0

	var desired = _prompt_anchor() + Vector2(-_prompt_size.x / 2.0, half_height + 8.0 + prompt_offset_y)
	var screen = get_viewport_rect().size
	desired.x = clamp(desired.x, 0.0, max(screen.x - _prompt_size.x, 0.0))
	desired.y = clamp(desired.y, 0.0, max(screen.y - bottom_reserved - _prompt_size.y, 0.0))
	_prompt_label.set_global_position(desired)
