extends PowerScript

@export var splash_damage : int = 0
@export var radius : int = 0

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	if source == null:
		return
	for target in _targets:
		if not is_instance_valid(target):
			continue
		var splash_targets : Array[Card_GUI] = []
		splash_targets.assign(get_splash(target.manager, target.manager_position, radius))
		for splash in splash_targets:
			splash.damage(ability, splash_damage, 0)

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
