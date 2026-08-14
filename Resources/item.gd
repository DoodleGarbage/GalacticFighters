extends Resource

class_name Item # / Gadget

var mod : Mod

var name : String = ""
var desc : String = ""

var icon : Texture

## The classification of this item, but is not super strictly enforced. Relevant for things like deck building
@export_enum("Item", "Gadget", "Sword")
var type : int = 0

var effect : Attribute

## -1 is infinite uses - 0 will make this item unusable
var uses : int = -1
### Make sure to duplicate this resource.
#var times_used : int = 0
## How much energy/points/whatever it costs to use this item/gadget
var cost : int = 0

func mod_name() -> String:
	return mod.name + ":" + name
