extends Node2D

onready var loading = $ProgressBar
export var load_game: String = "res://scenes/UI/game.tscn"
export var min_load_time: float = 1.5

var loader = null
var loaded_scene = null
var elapsed: float = 0.0

func _ready():
	loader = ResourceLoader.load_interactive(load_game)

func _process(delta):
	elapsed += delta

	if loader != null:
		var err = loader.poll()

		if err == ERR_FILE_EOF:
			loaded_scene = loader.get_resource()
			loader = null
			loading.value = 100
		elif err == OK:
			var pct = (float(loader.get_stage()) / float(loader.get_stage_count())) * 100
			loading.value = pct
		else:
			loader = null

	if loaded_scene != null and elapsed >= min_load_time:
		var scene = loaded_scene
		loaded_scene = null   # only ask once
		SceneTransition.change_scene_to(scene)
