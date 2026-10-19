extends Control
# Stage select for Chapter 3 (stages 3-1, 3-2 and 3-3): simple loops.
#   3-1  for loops and range
#   3-2  while loops
#   3-3  break, continue and running totals
# The chosen stage is stored on the SceneTree, so main.gd can read it after the loading screen.

const CHAPTER = 3
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


func _on_31_pressed():
	start_stage(1)


func _on_32_pressed():
	start_stage(2)


func _on_33_pressed():
	start_stage(3)
