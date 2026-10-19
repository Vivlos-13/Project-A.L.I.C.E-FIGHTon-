extends Control
# Stage select for Chapter 2 (stages 2-1, 2-2 and 2-3).
#   2-1  printing, a step further (sep, end, f-strings, str())
#   2-2  variables, a step further (swapping, +=, converting types)
#   2-3  arithmetic, a step further (order of operations, //, %, **, abs, round, min, max)
# The chosen stage is stored on the SceneTree, so main.gd can read it after the loading screen.

const CHAPTER = 2
const LOADING_SCENE = "res://scenes/UI/Chapterloading.tscn"   # the loading screen, which then opens the game


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func start_stage(stage: int) -> void:
	get_tree().set_meta("selected_chapter", CHAPTER)
	get_tree().set_meta("selected_stage", stage)
	get_tree().change_scene(LOADING_SCENE)


func _on_Return_pressed():
	get_tree().change_scene("res://scenes/UI/ChapterSelect.tscn")


func _on_21_pressed():
	start_stage(1)


func _on_22_pressed():
	start_stage(2)


func _on_23_pressed():
	start_stage(3)
