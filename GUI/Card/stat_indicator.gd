@tool
extends Control

@export var hide_on_zero : bool = false

@export var image : Texture2D :
	set(value):
		image = value
		$Life/imgStat.texture = image

@export var stat : int = 0 :
	set(value):
		stat = value
		if stat <= 0 and hide_on_zero:
			hide()
		else:
			show()
		$Life/statText.text = str(stat)
