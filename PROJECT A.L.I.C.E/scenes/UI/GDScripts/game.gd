extends Node2D

const MAIN_MENU_SCENE = "res://scenes/UI/main_menu.tscn"
const CHAPTER_COUNT = 5

# Stage 1-1 is the tutorial stage: these pages are shown when the game starts.
# Each page is [title, text]. ("\n" starts a new line.)
const TUTORIAL_PAGES = [
	["WELCOME TO STAGE 1-1", "This is the tutorial stage.\n\nMonsters are attacking Alice! Each one carries a line of Python code. Defeat them all to clear the stage."],
	["SOLVE THE CODE", "Fill in the blank (____) or type what the line prints, then press ENTER.\n\nTwo blanks? Separate your answers with a comma, like for,range."],
	["PICK A TARGET", "The enemy with the gold brackets is your target, and your answer goes to it.\n\nPress TAB to switch to another enemy."],
	["STAY ALIVE", "If an enemy reaches Alice she loses half a heart. Lose all your hearts and it is game over.\n\nDefeat every enemy on the counter to clear the stage. Good luck!"],
]
const STAGES_PER_CHAPTER = 3

# Most enemies allowed on screen at once (each one shows a line of code to read).
export var max_enemies: int = 3

# Enemies to defeat in a stage: stage 1 needs 10, and every stage after that needs 5 more.
export var base_enemy_limit: int = 10
export var enemy_limit_step: int = 5

# true: an answer only counts for the enemy you are targeting (Tab switches target).
# false: an answer can also defeat any other enemy on screen (the target is tried first).
export var target_only_answers: bool = true

# Gap between the bottom of the screen and the bottom of the typing box.
export var answer_box_bottom_margin: float = 5.0

# After the last enemy is defeated, wait this long so its death animation can play.
export var stage_clear_delay: float = 1.2

# How long the "stage cleared" message stays up before the next stage starts.
export var popup_time: float = 2.5
# The same for the message after the very last stage (5-3), before going back to the main menu.
export var final_popup_time: float = 4.0

var enemy_scenes = [
	preload("res://scenes/Entity/Enemy1.tscn"),   # butterfly
	preload("res://scenes/Entity/Enemy2.tscn"),   # worm
	preload("res://scenes/Entity/Enemy3.tscn")    # bee
]

onready var enemy_container = $EnemyContainer
onready var spawn_container = $SpawnContainer
onready var timer = $SpawnTimer

var click_sound = preload("res://sounds/click.ogg")
var miss_sound = preload("res://sounds/miss.wav")

onready var click_player = AudioStreamPlayer.new()
onready var miss_player = AudioStreamPlayer.new()

var challenge_bank = ChallengeBank.new()
var answer_box: LineEdit = null
var flash_tween: Tween = null
var target_enemy = null   # the enemy that is highlighted and gets the answer

var _chapter: int = 1
var _stage: int = 1
var enemy_limit: int = 10
var enemies_defeated: int = 0
var _stage_cleared: bool = false

var enemy_count_label = null   # RichTextLabel "EnemyCount":  Enemies: x/x
var stage_text_label = null    # RichTextLabel "StageText":   Stage x-x

var popup_tween: Tween = null
var _popup_layer = null
var _popup_panel = null
var _popup_title = null
var _popup_subtitle = null

var _tutorial_active: bool = false
var _tutorial_page: int = 0
var _tutorial_layer = null
var _tutorial_panel = null
var _tutorial_title = null
var _tutorial_body = null
var _tutorial_footer = null


func _ready() -> void:
	randomize()

	enemy_count_label = find_node("EnemyCount", true, false)
	stage_text_label = find_node("StageText", true, false)
	if enemy_count_label == null:
		push_warning("main: no RichTextLabel named 'EnemyCount' found")
	if stage_text_label == null:
		push_warning("main: no RichTextLabel named 'StageText' found")

	click_player.stream = click_sound
	click_player.volume_db = linear2db(0.1)
	add_child(click_player)

	miss_player.stream = miss_sound
	miss_player.volume_db = linear2db(0.1)
	add_child(miss_player)

	flash_tween = Tween.new()
	add_child(flash_tween)
	popup_tween = Tween.new()
	add_child(popup_tween)

	_build_popup()
	_build_tutorial()
	_setup_answer_box()

	_begin_stage(1, 1)   # the game always starts at stage 1-1, the tutorial stage
	timer.start()
	_start_tutorial()    # no enemy spawns until the tutorial is finished


func _process(_delta: float) -> void:
	# Keep the cursor in the text box so the player can always just type.
	if answer_box != null and not answer_box.has_focus():
		answer_box.grab_focus()
	_refresh_target()


# Tab switches the target. This runs before the text box sees the key, otherwise the
# text box would use Tab to move keyboard focus. Shift+Tab goes the other way.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key = event as InputEventKey

	if _tutorial_active:
		# while the tutorial is open the keys only drive the tutorial
		if key.pressed and not key.echo:
			if key.scancode == KEY_ENTER or key.scancode == KEY_KP_ENTER or key.scancode == KEY_SPACE:
				_advance_tutorial()
			elif key.scancode == KEY_ESCAPE:
				_finish_tutorial()
		get_tree().set_input_as_handled()
		return

	if key.pressed and not key.echo and key.scancode == KEY_TAB:
		_cycle_target(-1 if key.shift else 1)
		get_tree().set_input_as_handled()


# ---------------------------------------------------------------------
# The text box the player types into
# ---------------------------------------------------------------------

# Uses a LineEdit named "AnswerBox" if you added one to the scene (so you can place
# and style it yourself); otherwise makes one at the bottom centre of the screen.
func _setup_answer_box() -> void:
	answer_box = find_node("AnswerBox", true, false)
	if answer_box == null:
		var layer = CanvasLayer.new()
		add_child(layer)
		answer_box = LineEdit.new()
		layer.add_child(answer_box)
		var screen = get_viewport_rect().size
		answer_box.rect_size = Vector2(420, 36)
		answer_box.rect_position = Vector2((screen.x - 420) / 2.0, screen.y - answer_box_bottom_margin - 36)
		answer_box.align = LineEdit.ALIGN_CENTER

	answer_box.placeholder_text = "type your answer, Enter to send (Tab: switch target)"
	answer_box.max_length = 60
	answer_box.connect("text_entered", self, "_on_answer_entered")
	answer_box.connect("text_changed", self, "_on_answer_changed")
	answer_box.grab_focus()


func _on_answer_changed(_new_text: String) -> void:
	_play_click()   # typing sound on every keystroke


func _on_answer_entered(new_text: String) -> void:
	if _stage_cleared:
		return
	var answer = new_text.strip_edges()
	if answer == "":
		return

	var enemy = _find_enemy_for(answer)
	if enemy != null:
		print("correct: %s" % answer)
		_play_click()
		enemy.defeat()
		answer_box.clear()

		enemies_defeated += 1
		_update_hud()
		if enemies_defeated >= enemy_limit:
			_stage_clear()
	else:
		print("wrong: %s" % answer)
		_play_miss()
		answer_box.select_all()   # typing again replaces it
		_flash_answer_box()


# The answer goes to the target. With target_only_answers off, any other enemy can
# take it too (if several match, the one closest to the player is defeated).
func _find_enemy_for(answer: String):
	_refresh_target()
	if is_instance_valid(target_enemy) and target_enemy.can_be_hit() and target_enemy.check_answer(answer):
		return target_enemy
	if target_only_answers:
		return null

	var best = null
	var best_distance = INF
	for enemy in enemy_container.get_children():
		if not enemy.can_be_hit():
			continue   # already attacking or dying
		if enemy.check_answer(answer):
			var distance = enemy.get_distance_to_target()
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best


func _flash_answer_box() -> void:
	flash_tween.stop_all()
	flash_tween.interpolate_property(
		answer_box, "modulate",
		Color(1.0, 0.4, 0.4), Color(1.0, 1.0, 1.0),
		0.35, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	flash_tween.start()


# ---------------------------------------------------------------------
# Targeting: the highlighted enemy is the one your answer is for
# ---------------------------------------------------------------------

# Every enemy that can still be answered, in the order they appeared.
func _hittable_enemies() -> Array:
	var result = []
	for enemy in enemy_container.get_children():
		if enemy.can_be_hit():
			result.append(enemy)
	return result


func _set_target(enemy) -> void:
	if is_instance_valid(target_enemy):
		target_enemy.set_targeted(false)
	target_enemy = enemy
	if enemy != null:
		enemy.set_targeted(true)


# Keeps a valid target: when there is none (the target was defeated, attacked, or nothing
# was targeted yet) the enemy closest to the player is picked.
func _refresh_target() -> void:
	if is_instance_valid(target_enemy) and target_enemy.can_be_hit():
		return
	var closest = null
	var closest_distance = INF
	for enemy in _hittable_enemies():
		var distance = enemy.get_distance_to_target()
		if distance < closest_distance:
			closest = enemy
			closest_distance = distance
	_set_target(closest)


# Tab: move to the next enemy (Shift+Tab: the previous one).
func _cycle_target(direction: int) -> void:
	var candidates = _hittable_enemies()
	if candidates.size() < 2:
		return   # nothing else to switch to
	var index = candidates.find(target_enemy)
	index = (index + direction + candidates.size()) % candidates.size()
	_set_target(candidates[index])
	_play_click()


# ---------------------------------------------------------------------
# Spawning
# ---------------------------------------------------------------------

func _on_SpawnTimer_timeout():
	if _stage_cleared or _tutorial_active:
		return
	# Keep going until the stage goal is reached, but never spawn more enemies
	# than are still needed (defeated + on screen must stay below the limit).
	var alive = _alive_enemy_count()
	if alive < max_enemies and enemies_defeated + alive < enemy_limit:
		spawn()


# Enemies still approaching (one that is attacking or dying is already on its way out).
func _alive_enemy_count() -> int:
	var count = 0
	for enemy in enemy_container.get_children():
		if enemy.can_be_hit():
			count += 1
	return count


func spawn():
	var spawn_points = spawn_container.get_children()
	if spawn_points.empty():
		return
	var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy_spawn = enemy_scene.instance()
	var index = randi() % spawn_points.size()
	enemy_container.add_child(enemy_spawn)
	enemy_spawn.global_position = spawn_points[index].global_position
	# each enemy type decides what it asks (challenge_kind in Enemy1.gd, Enemy2.gd, Enemy3.gd)
	enemy_spawn.set_challenge(challenge_bank.next_challenge(enemy_spawn.challenge_kind))


# ---------------------------------------------------------------------
# Stage info and finishing the stage
# ---------------------------------------------------------------------

func _update_hud() -> void:
	_set_label_text(enemy_count_label, "Enemies: %d/%d" % [enemies_defeated, enemy_limit])
	_set_label_text(stage_text_label, "Stage %d-%d" % [_chapter, _stage])


func _set_label_text(label, value: String) -> void:
	if label == null:
		return
	if label.bbcode_enabled:
		label.bbcode_text = "[center]%s[/center]" % value   # same centred look as the scene
	else:
		label.text = value


# Sets up stage `stage` of chapter `chapter` (1-1 ... 5-3).
func _begin_stage(chapter: int, stage: int) -> void:
	_chapter = chapter
	_stage = stage
	challenge_bank.set_stage(_chapter, _stage)
	enemy_limit = base_enemy_limit + enemy_limit_step * (_stage - 1)
	enemies_defeated = 0
	_stage_cleared = false
	_update_hud()
	print("Chapter %d - Stage %d (defeat %d enemies)" % [_chapter, _stage, enemy_limit])


func _is_last_stage() -> bool:
	return _chapter >= CHAPTER_COUNT and _stage >= STAGES_PER_CHAPTER


# The stage that follows this one, as [chapter, stage].
func _next_stage_numbers() -> Array:
	if _stage < STAGES_PER_CHAPTER:
		return [_chapter, _stage + 1]
	return [_chapter + 1, 1]


func _stage_clear() -> void:
	_stage_cleared = true
	print("Stage %d-%d cleared!" % [_chapter, _stage])
	# give the last enemy's death animation time to play, then show the message
	_after(stage_clear_delay, "_show_clear_popup")


func _show_clear_popup() -> void:
	if _is_last_stage():
		_show_popup("ALL STAGES CLEARED!", "Congratulations! You finished the game.")
		_after(final_popup_time, "_finish_game")
	else:
		var next = _next_stage_numbers()
		_show_popup("STAGE %d-%d CLEARED!" % [_chapter, _stage], "Next: Stage %d-%d" % [next[0], next[1]])
		_after(popup_time, "_go_to_next_stage")


# Starts the next stage automatically, with Alice's hearts left as they are.
func _go_to_next_stage() -> void:
	_hide_popup()
	_set_target(null)
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	answer_box.clear()
	var next = _next_stage_numbers()
	_begin_stage(next[0], next[1])
	spawn()


func _finish_game() -> void:
	var err = get_tree().change_scene(MAIN_MENU_SCENE)
	if err != OK:
		push_error("main: could not open %s (error %s)" % [MAIN_MENU_SCENE, err])


# Calls `method` once, after `seconds`.
func _after(seconds: float, method: String) -> void:
	var wait = Timer.new()
	wait.one_shot = true
	wait.wait_time = max(seconds, 0.01)
	add_child(wait)
	wait.connect("timeout", self, method)
	wait.connect("timeout", wait, "queue_free")
	wait.start()


# ---------------------------------------------------------------------
# The tutorial (stage 1-1): a few pages, then the enemies start to spawn
# ---------------------------------------------------------------------

func _build_tutorial() -> void:
	var screen = get_viewport_rect().size
	var panel_size = Vector2(min(screen.x - 40.0, 760.0), 340.0)

	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 60   # above everything, including the stage cleared message
	add_child(_tutorial_layer)

	_tutorial_panel = Panel.new()
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_panel.rect_size = panel_size
	_tutorial_panel.rect_position = (screen - panel_size) / 2.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.105882, 0.027451, 0.12549)
	style.border_color = Color(0.768627, 0.133333, 0.878431)
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	_tutorial_panel.add_stylebox_override("panel", style)
	_tutorial_layer.add_child(_tutorial_panel)

	_tutorial_title = _make_label_in(_tutorial_panel, 24, Color(0.109804, 0.8, 1.0))
	_tutorial_title.rect_position = Vector2(20, 24)
	_tutorial_title.rect_size = Vector2(panel_size.x - 40.0, 40)

	_tutorial_body = _make_label_in(_tutorial_panel, 14, Color(1, 1, 1))
	_tutorial_body.valign = Label.VALIGN_TOP
	_tutorial_body.rect_position = Vector2(30, 84)
	_tutorial_body.rect_size = Vector2(panel_size.x - 60.0, 180)

	_tutorial_footer = _make_label_in(_tutorial_panel, 10, Color(0.75, 0.75, 0.85))
	_tutorial_footer.rect_position = Vector2(20, panel_size.y - 48.0)
	_tutorial_footer.rect_size = Vector2(panel_size.x - 40.0, 30)

	_tutorial_panel.visible = false


func _start_tutorial() -> void:
	_tutorial_active = true
	_tutorial_page = 0
	answer_box.clear()
	answer_box.editable = false   # no typing while the tutorial is open
	_show_tutorial_page()
	_tutorial_panel.modulate = Color(1, 1, 1, 0)
	_tutorial_panel.visible = true
	popup_tween.stop_all()
	popup_tween.interpolate_property(
		_tutorial_panel, "modulate",
		Color(1, 1, 1, 0), Color(1, 1, 1, 1),
		0.3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	popup_tween.start()


func _show_tutorial_page() -> void:
	var page = TUTORIAL_PAGES[_tutorial_page]
	_tutorial_title.text = page[0]
	_tutorial_body.text = page[1]
	var counter = "(%d/%d)" % [_tutorial_page + 1, TUTORIAL_PAGES.size()]
	if _tutorial_page < TUTORIAL_PAGES.size() - 1:
		_tutorial_footer.text = "ENTER: next    ESC: skip    " + counter
	else:
		_tutorial_footer.text = "ENTER: start    " + counter


func _advance_tutorial() -> void:
	_play_click()
	_tutorial_page += 1
	if _tutorial_page >= TUTORIAL_PAGES.size():
		_finish_tutorial()
	else:
		_show_tutorial_page()


# The tutorial is over (finished or skipped): now the enemies can come.
func _finish_tutorial() -> void:
	if not _tutorial_active:
		return
	_tutorial_active = false
	popup_tween.stop_all()
	_tutorial_panel.visible = false
	answer_box.editable = true
	answer_box.grab_focus()
	timer.start()   # restart the spawn timer so the first gap is a full one
	spawn()


# ---------------------------------------------------------------------
# The "stage cleared" message
# ---------------------------------------------------------------------

func _build_popup() -> void:
	var screen = get_viewport_rect().size
	var popup_size = Vector2(min(screen.x - 40.0, 720.0), 190.0)

	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 50   # above the game and its labels
	add_child(_popup_layer)

	_popup_panel = Panel.new()
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_panel.rect_size = popup_size
	_popup_panel.rect_position = (screen - popup_size) / 2.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.105882, 0.027451, 0.12549)         # the dark purple of the other screens
	style.border_color = Color(0.768627, 0.133333, 0.878431)    # magenta border
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	_popup_panel.add_stylebox_override("panel", style)
	_popup_layer.add_child(_popup_panel)

	_popup_title = _make_popup_label(30, Color(0.109804, 0.8, 1.0))
	_popup_title.rect_position = Vector2(20, 36)
	_popup_title.rect_size = Vector2(popup_size.x - 40.0, 50)

	_popup_subtitle = _make_popup_label(14, Color(1, 1, 1))
	_popup_subtitle.rect_position = Vector2(20, 112)
	_popup_subtitle.rect_size = Vector2(popup_size.x - 40.0, 40)

	_popup_panel.visible = false


func _make_popup_label(font_size: int, color: Color) -> Label:
	return _make_label_in(_popup_panel, font_size, color)


func _make_label_in(parent: Control, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.autowrap = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font_data = load("res://fonts/PressStart2P-Regular.ttf")   # the font the other screens use
	if font_data != null:
		var font = DynamicFont.new()
		font.font_data = font_data
		font.size = font_size
		label.add_font_override("font", font)
	label.add_color_override("font_color", color)
	parent.add_child(label)
	return label


func _show_popup(title: String, subtitle: String) -> void:
	_popup_title.text = title
	_popup_subtitle.text = subtitle
	_popup_panel.modulate = Color(1, 1, 1, 0)
	_popup_panel.visible = true
	popup_tween.stop_all()
	popup_tween.interpolate_property(
		_popup_panel, "modulate",
		Color(1, 1, 1, 0), Color(1, 1, 1, 1),
		0.3, Tween.TRANS_LINEAR, Tween.EASE_IN
	)
	popup_tween.start()


func _hide_popup() -> void:
	popup_tween.stop_all()
	_popup_panel.visible = false


# ---------------------------------------------------------------------
# Sound (never overlapping itself)
# ---------------------------------------------------------------------

func _play_click() -> void:
	if not click_player.playing:
		click_player.play()


func _play_miss() -> void:
	if not miss_player.playing:
		miss_player.play()
