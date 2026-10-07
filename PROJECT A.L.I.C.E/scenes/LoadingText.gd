extends RichTextLabel

const BASE_TEXT = "Loading"
const MAX_DOTS = 4

export var interval: float = .2

var dots: int = 1
var elapsed: float = 0.0


func _ready():
	update_text()


func _process(delta):
	elapsed += delta
	if elapsed >= interval:
		elapsed -= interval
		dots += 1
		if dots > MAX_DOTS:
			dots = 1
		update_text()


func update_text():
	text = BASE_TEXT + "....".substr(0, dots)
