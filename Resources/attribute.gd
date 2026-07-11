extends Resource
class_name Attribute

@export
var name : String = ""

@export
var icon : Texture

@export
var pscript : GDScript

@export
var pscript_sync_data : Array[StringName] = []

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
@export_flags("Self", "Allies", "Enemies", "Allies (Saferoom)", "Enemies (Saferoom)")
var target_type : int = 0
## Targeting
# (1)   0b00001: self
# (2)   0b00010: allies
# (4)   0b00100: enemies
# (8)   0b01000: allies (saferoom)
# (16)  0b10000: enemies (saferoom)

@export_flags("Empty")
var allowed_metadata : int = 0
## Flags based, as opposed to an array of strings currently. TODO: The cards should be updated to use int metadata or use an array of strings


## The effect that is displayed when an ability is used on a character
var VFX_target : PackedScene

var VFX_damage : PackedScene

## The sound effect that is displayed when an ability is used
#var sound_effect_trigger : AudioEffect

## Duration
## The length of the ability - decreases by 1 at the end of each turn, deleted at 0. If less than 0, infinite duration.
var duration : int = -1
