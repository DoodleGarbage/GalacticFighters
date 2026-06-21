@tool
extends Control


@export var image : Texture2D :
	set(value):
		image = value
		$Life/imgStat.texture = image

@export var stat : int = 0 :
	set(value):
		stat = value
		$Life/statText.text = str(stat)
