extends Resource

class_name Item

var name : String = ""

var icon : Texture

var targets : int = 0

var target_type : int = 0

## -1 is infinity
var uses : int = -1
## Make sure to duplicate this resource.
var times_used : int = 0
