extends Control
# Stage select for Chapter 1 (stages 1-1, 1-2 and 1-3).
#   1-1  printing
#   1-2  variables
#   1-3  basic arithmetic
# The chosen stage is stored on the SceneTree, so main.gd can read it after the loading screen.

const CHAPTER = 1
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


func _on_11_pressed():
	start_stage(1)


func _on_12_pressed():
	start_stage(2)


func _on_13_pressed():
	start_stage(3)
