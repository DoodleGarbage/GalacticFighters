extends Resource
class_name Attribute

var mod : Mod

@export var name : String = ""

@export var icon : Texture

@export var pscript : GDScript

## Used to set the values of the pscript when initalized
@export var script_variables : Dictionary = {}

@export var pscript_sync_data : Array[StringName] = []

@export_enum("Passive", "Ability", "Interaction", "Status")
var type : int = 0

var interaction_type : String = ""

							# max health, attack, defense, burst, heal, armor pierce
var modified_stats : Array[int] = []

@export_enum("Apply Duplicate", "Reset Duration", "Increase Duration", "Increase Variables", "Reset and Increase")
var application_behavior : int = 0



## Do not put full descriptions here, prefer using a translated string.
@export var desc : String = "DESCRIPTION_LANG"



@export var targeting : TargetData

## The effect that is displayed when an ability is used on a character
var VFX_target : PackedScene

var VFX_damage : PackedScene

## Duration
## The length of the ability - decreases by 1 at the end of each turn, deleted at 0. If less than 0, infinite duration.
var duration : int = -1

func mod_name() -> String:
	return mod.name + ":" + name
