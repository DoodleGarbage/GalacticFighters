@tool
extends Range

class_name SpinBoxModified

func _ready() -> void:
	update_label(value)

func increment() -> void:
	value += step
func decrement() -> void:
	value -= step
func update_label(_val:float) -> void:
	$Spin/NumTex/Text/Number.text = str(int(_val)) if rounded else str(_val)
func update_size() -> void:
	custom_minimum_size = $Spin.size
