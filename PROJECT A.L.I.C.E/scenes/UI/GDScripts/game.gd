extends Node2D

const STAGE_CLEAR_SCENE = "res://scenes/UI/StageClear.tscn"

# Most enemies allowed on screen at once (each one shows a line of code to read).
export var max_enemies: int = 3

# Enemies to defeat in a stage: stage 1 needs 10, and every stage after that needs 5 more.
export var base_enemy_limit: int = 10
export var enemy_limit_step: int = 5

# Gap between the bottom of the screen and the bottom of the typing box.
export var answer_box_bottom_margin: float = 5.0

# After the last enemy is defeated, wait this long so its death animation can play.
export var stage_clear_delay: float = 1.2

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

var _chapter: int = 1
var _stage: int = 1
var enemy_limit: int = 10
var enemies_defeated: int = 0
var _stage_cleared: bool = false

var enemy_count_label = null   # RichTextLabel "EnemyCount":  Enemies: x/x
var stage_text_label = null    # RichTextLabel "StageText":   Stage x-x


func _ready() -> void:
	randomize()

	# Which stage was chosen on the chapter screen (defaults to 1-1 if this scene is run directly)
	_chapter = _selected("selected_chapter", 1)
	_stage = _selected("selected_stage", 1)
	challenge_bank.set_stage(_chapter, _stage)
	enemy_limit = base_enemy_limit + enemy_limit_step * (_stage - 1)
	print("Chapter %d - Stage %d (defeat %d enemies)" % [_chapter, _stage, enemy_limit])

	enemy_count_label = find_node("EnemyCount", true, false)
	stage_text_label = find_node("StageText", true, false)
	if enemy_count_label == null:
		push_warning("main: no RichTextLabel named 'EnemyCount' found")
	if stage_text_label == null:
		push_warning("main: no RichTextLabel named 'StageText' found")
	_update_hud()

	click_player.stream = click_sound
	click_player.volume_db = linear2db(0.1)
	add_child(click_player)

	miss_player.stream = miss_sound
	miss_player.volume_db = linear2db(0.1)
	add_child(miss_player)

	flash_tween = Tween.new()
	add_child(flash_tween)

	_setup_answer_box()

	timer.start()
	spawn()


# The chapter screens store the player's choice on the SceneTree, which survives scene changes.
func _selected(key: String, default_value: int) -> int:
	if get_tree().has_meta(key):
		return int(get_tree().get_meta(key))
	return default_value


func _process(_delta: float) -> void:
	# Keep the cursor in the text box so the player can always just type.
	if answer_box != null and not answer_box.has_focus():
		answer_box.grab_focus()


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

	answer_box.placeholder_text = "type your answer, then press Enter"
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


# The answer can belong to any enemy on screen. If several match,
# the one closest to the player is the one that gets defeated.
func _find_enemy_for(answer: String):
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
# Spawning
# ---------------------------------------------------------------------

func _on_SpawnTimer_timeout():
	if _stage_cleared:
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
	if label != null:
		label.bbcode_text = value   # also fine when BBCode is switched off on the label


func _stage_clear() -> void:
	_stage_cleared = true
	print("Stage %d-%d cleared!" % [_chapter, _stage])
	# give the last enemy's death animation time to play before leaving the stage
	var wait = Timer.new()
	wait.one_shot = true
	wait.wait_time = max(stage_clear_delay, 0.01)
	add_child(wait)
	wait.connect("timeout", self, "_open_stage_clear_scene")
	wait.start()


func _open_stage_clear_scene() -> void:
	var err = get_tree().change_scene(STAGE_CLEAR_SCENE)
	if err != OK:
		push_error("main: could not open %s (error %s)" % [STAGE_CLEAR_SCENE, err])


# ---------------------------------------------------------------------
# Sound (never overlapping itself)
# ---------------------------------------------------------------------

func _play_click() -> void:
	if not click_player.playing:
		click_player.play()


func _play_miss() -> void:
	if not miss_player.playing:
		miss_player.play()
