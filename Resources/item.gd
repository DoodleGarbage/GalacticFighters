extends Resource

class_name Item # / Gadget

var name : String = ""
var desc : String = ""


var icon : Texture

var effect : Attribute

## -1 is infinity
var uses : int = -1
## Make sure to duplicate this resource.
var times_used : int = 0
## How much energy/points/whatever it costs to use this item/gadget
var cost : int = 0
