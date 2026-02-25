extends Resource
class_name Ability

@export
var name : String = "NA"

@export_enum("Passive", "Ability", "Interaction")
var type : int = 0

## Do not put full descriptions here, prefer using a translated string.
@export
var desc : String = "DESCRIPTION_LANG"
