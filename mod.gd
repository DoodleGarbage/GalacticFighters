extends Resource
class_name Mod

## Used to ensure mods with the same name and ver but are still different are identified correctly
var mod_id : int

var enabled : bool = true :
	set(value):
		enabled = value
		hash = [] # Reset the hash if the mod is disabled - will only be re-set when the mod is loaded again

var name : String = ""
var version : Array[int] = []

var hashing_context : HashingContext # Used to generate the hash of this mod. 
@warning_ignore("shadowed_global_identifier")
var hash : PackedByteArray = []

var desc : String = ""

## Mod Loading Information (used by Resources)
var mod_path : String = ""
var internal : bool = false

func is_valid_mod() -> bool:
	var valid : bool = not name == ""
	#valid = valid and not version == []
	return valid

func version_as_string() -> String:
	var result : String = str(version[0]) if version.size() > 0 else ""
	if result == "" or version.size() == 1:
		return result
	for i in version.size() - 1:
		result += "." + str(version[i+1])
	return result
