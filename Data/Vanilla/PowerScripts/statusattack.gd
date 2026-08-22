extends PowerScript

@export var status : String = ""

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	if source == null:
		return
	for target in _targets:
		if not is_instance_valid(target):
			continue
		target.damage(ability, source.get_attack(), source.get_armor_pierce())
		target.apply_status(status)

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
