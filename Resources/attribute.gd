extends Resource
class_name Attribute

@export
var name : String = ""

@export
var icon : Texture

@export
var pscript : GDScript

@export_enum("Passive", "Ability", "Interaction", "Status")
var type : int = 0

## Do not put full descriptions here, prefer using a translated string.
@export
var desc : String = "DESCRIPTION_LANG"

## Whether or not this attribute can be multiplied by Burst
@export
var allow_burst : bool = false

## The number of targets to be selected - if negative, will automatically select all cards in the valid groups.
@export
var targets : int = -1

# The targeting method - uses a bit flag to check which cards to target are valid
@export_flags("Allies", "Enemies", "Allies (Saferoom)", "Enemies (Saferoom)")
var target_type : int = 0
## Targeting
#export targeting details
# 0b0000: self
# 0b0001: allies
# 0b0010: enemies
# 0b0100: allies (saferoom)
# 0b1000: enemies (saferoom)
