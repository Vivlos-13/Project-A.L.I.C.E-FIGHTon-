extends Timer

func _ready():
	randomize()
	connect("timeout", self, "_on_timeout")
	_randomize_wait_time()
	start()

func _on_timeout():
	_randomize_wait_time()

func _randomize_wait_time():
	wait_time = rand_range(2.0, 3.0)
