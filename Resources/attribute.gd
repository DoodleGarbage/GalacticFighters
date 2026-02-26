extends Resource
class_name RootAttribute

@export
var name : String = ""

@export
var pscript : PowerScript

@export_enum("Passive", "Ability", "Interaction", "Status")
var type : int = 0

## Do not put full descriptions here, prefer using a translated string.
@export
var desc : String = "DESCRIPTION_LANG"

## Targeting
#export targeting details
