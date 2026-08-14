extends Node

## TODO: Move decks to be saved to a user-side .json file (coincides with making the Deck Builder)
## TODO: Save the loaded mods on/off state to a .ini config file on user-side (instead of auto-enabling everything on load)


func _init() -> void:
	for internal in [true,false]:
		init_mods(internal)
	reload_mods()

## Default Resources

const VFX_character_death : PackedScene = preload("res://Data/Vanilla/VFX/death_vfx.tscn")
const VFX_null : PackedScene = preload("res://Data/Vanilla/VFX/null_vfx.tscn")

## Tracks which mods are considered 'loaded' - TODO: read from a saved "Mod List" .txt file, and automatically add newly loaded mods to it
var loaded_mods : Array[Mod] = []
var loaded_hash : PackedByteArray = []

## Loaded Resources

var attributes : Array[Attribute] = []
var pscripts : Array[GDScript] = [] # PowerScripts, but can't be a typed array
var characters : Array[Card] = []
var items : Array[Item] = []
var decks : Array[Deck] = []
var vfx : Array[PackedScene] = [] ## Isn't restricted to particle effect nodes to allow for more creative effects, so long as the root node script has a few properties of GPUParticle2D - namely, 'position',  'amount', 'emitting', and signal 'finished'
var images : Array[Texture] = []

func reload_mods() -> void:
	attributes = []
	pscripts = []
	characters = []
	decks = []
	vfx = []
	images = []
	for mod in loaded_mods:
		if mod.enabled:
			verify_mod(mod)
	for mod in loaded_mods:
		if mod.enabled:
			load_mod(mod)
	var total_hash := HashingContext.new()
	total_hash.start(HashingContext.HASH_MD5)
	for mod in loaded_mods:
		if not mod.enabled:
			continue
		total_hash.update(mod.hash)
	loaded_hash = total_hash.finish()


## Resource search functions

func find_resource(resource_type:String, resource_name:String) -> Variant:
	var search_array : Array = []
	match(resource_type):
		"Attribute": search_array = attributes
		"Character": search_array = characters
		"Deck": search_array = decks
		"Item": search_array = items
		"String":
			return resource_name
		"Images": ## Just an extra way to search for images (redundancy! or bloat...)
			return find_image(resource_name)
		"Pscript", "PowerScript", "VFX":
			return find_scene(resource_type, resource_name)
		_: push_error("Resource array for resource type %s does not exist!" % resource_type); return
	var split : PackedStringArray = resource_name.split(":",false,1)
	if split.size() < 2:
		push_error("Tried to search for resource (Type: %s, Name: %s) but no mod was specified! Specify a mod using ':'." % [resource_type, resource_name])
		return null
	for resource in search_array:
		if resource.name == split[1] and resource.mod.name == split[0]:
			return resource
	push_warning("Could not find resource of type %s for name \"%s\"!" % [resource_type, resource_name])
	return null

func find_image(imagename:String) -> Texture:
	for image : Texture in images:
		if image.resource_name == imagename:
			return image
	return null

## For some reason, script must return as GDscript and cannot be an extending type (PowerScript) - probably due to how they're initalized only later and the 'Classname' and other properties aren't known until later, JIT compilation shit or something
func find_scene(scene_type : String, scenename:String) -> Variant:
	var search_array : Array = []
	match(scene_type):
		"VFX": search_array = vfx
		"PowerScript", "Pscript": search_array = pscripts
	for scene in search_array:
		if scene.resource_name == scenename:
			return scene
	return null



## Resource load functions

func init_mods(internal:bool) -> void:
	var mod_path : String = "res://Data/" if internal else "user://Image/"
	var dir = DirAccess.open(mod_path)
	if !dir:
		push_warning("No mods were found inside %s!" % mod_path)
	dir.list_dir_begin()
	var current_mod : String = dir.get_next()
	while current_mod != "":
		if not dir.current_is_dir():
			pass
		else:
			var mod_dir = DirAccess.open(mod_path + current_mod)
			mod_dir.list_dir_begin()
			var mod_file : String = mod_dir.get_next()
			var new_mod : Mod = Mod.new()
			while mod_file != "":
				## This block of code searches for a .ini file that has "modname = name_of_mod_here" then sets the 'mod' property for everything to this mod name
				## NOTE: Add any mod config reads here
				if not mod_file.ends_with(".ini") or mod_dir.current_is_dir():
					mod_file = mod_dir.get_next()
					continue
				var mod_file_read := FileAccess.open(mod_path + current_mod + "/" + mod_file, FileAccess.READ)
				while mod_file_read.get_position() < mod_file_read.get_length():
					var line : String = mod_file_read.get_line()
					line = line.remove_char(32) # From ASCII table, decimal, 32 is the space character
					var split : PackedStringArray = line.split("=",false,1)
					if split.size() >= 2 and split[0].to_lower() == "modname":
						new_mod.name = split[1]
					if split.size() >= 2 and split[0].to_lower() == "modversion":
						for ver:String in split[1].split(".",false):
							new_mod.version.append(ver.to_int())
				## EOF mod .ini
				## NOTE: if there are multiple .ini files, we'll read all of them, any new definitions of modname or modversion overwriting the old one
				mod_file = mod_dir.get_next()
			if not new_mod.is_valid_mod():
				push_warning("A mod (%s) did not have a valid mod config!" % current_mod)
				current_mod = dir.get_next()
				continue
			new_mod.mod_id = get_unique_mod_id()
			new_mod.mod_path = mod_path + current_mod
			new_mod.internal = internal
			loaded_mods.append(new_mod)
			verify_mod(new_mod)
		current_mod = dir.get_next()

## Checks if the mod is newer (and disables any older mods), disabled if it is less new than any other mod and ultimately returns if the mod is enabled/disabled.
func verify_mod(mod:Mod) -> bool:
	var name_check : Callable = func(element:Mod): return mod.name == element.name and element.enabled and element.mod_id != mod.mod_id # Wowie I used a lambda :)
	var check : int = loaded_mods.find_custom(name_check)
	var we_are_newer : bool = false
	while check > -1 and not we_are_newer:
		var i : int = 0
		
		while ( i < loaded_mods[check].version.size() and i < mod.version.size()):
			if mod.version[i] > loaded_mods[check].version[i]:
				we_are_newer = true
				break
			i += 1
		if not we_are_newer and mod.version.size() > loaded_mods[check].version.size():
			we_are_newer = true
		if not we_are_newer:
			mod.enabled = false
			break
		else:
			push_warning("Disabled mod %s (ver %s) as a newer version was loaded (%s)" % [loaded_mods[check].name, loaded_mods[check].version, mod.version])
			loaded_mods[check].enabled = false
			check = loaded_mods.find_custom(name_check)
			continue
	return mod.enabled

## Returns an ID not shared by all other cards
func get_unique_mod_id() -> int:
	var invalid_id : bool = true
	var new_id : int = 0
	while invalid_id:
		new_id = randi()
		invalid_id = false
		for mod in loaded_mods:
			if mod.mod_id == new_id:
				invalid_id = true
	return new_id


func load_mod(mod:Mod) -> void:
	mod.hashing_context = HashingContext.new()
	mod.hashing_context.start(HashingContext.HASH_MD5)
	load_images(mod.mod_path, mod, mod.internal)
	load_scene(mod.mod_path, mod, "VFX", mod.internal)
	load_scene(mod.mod_path, mod, "PowerScript", mod.internal)
	load_resource(mod.mod_path, mod, "Attribute", mod.internal)
	load_resource(mod.mod_path, mod, "Character", mod.internal)
	load_resource(mod.mod_path, mod, "Item", mod.internal)
	load_resource(mod.mod_path, mod, "Deck", mod.internal)
	mod.hash = mod.hashing_context.finish()


func load_images(mod_path:String, mod:Mod, internal:bool) -> void:
	var dir_path : String = mod_path + "/Images"
	var dir = DirAccess.open(dir_path)
	if !dir:
		#push_warning("No folder was found for %s!" % dir_path)
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			pass
		elif current_file.ends_with(".png") or current_file.ends_with(".jpg") or current_file.ends_with(".jpeg"):
			if internal: ## We need special loading handling if we're loading in res://, as load_from_file will not work on export.
				var new_text : Texture = load(dir_path + "/" + current_file)
				new_text.resource_name = mod.name + ":" + current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
				images.append(new_text)
				current_file = dir.get_next()
				continue
			var new_image : Image = Image.load_from_file(dir_path + current_file)
			if new_image == null:
				push_error("Found image, but couldn't load it as an image!")
				current_file = dir.get_next()
				continue
			var as_texture = ImageTexture.create_from_image(new_image)
			as_texture.resource_name = mod.name + ":" +  current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
			images.append(as_texture)
		current_file= dir.get_next()
	return

func load_scene(mod_path : String, mod:Mod, resource_type : String, internal:bool=true) -> void:
	var directory : String = mod_path + ("/%s" % (resource_type + "s"))
	var dir : DirAccess = DirAccess.open(directory)
	if !dir:
		#push_warning("No folder was found for %s: %s" % [resource_type, directory])
		return
	dir.list_dir_begin()
	var next : String = dir.get_next()
	while next != "":
		if dir.current_is_dir():
			push_warning("Directory \"%s\" found inside %s folder. This directory is being ignored." % [next, directory])
			next = dir.get_next()
			continue
		if (resource_type == "PowerScript" and not next.ends_with(".gd")) or (resource_type == "VFX" and not next.ends_with(".tscn")):
			#push_warning("There is an incorrect file type for %s in directory. File: %s" % [resource_type, directory + next])
			next = dir.get_next()
			continue
		var new_scene = load(directory + "/" + next)
		new_scene.resource_name = mod.name + ":" + next.trim_suffix(".gd").trim_suffix(".tscn")
		match(resource_type):
			"VFX": vfx.append(new_scene)
			"PowerScript": 
				mod.hashing_context.update(FileAccess.get_file_as_bytes(directory + "/" + next))
				pscripts.append(new_scene)
		next = dir.get_next()
	return


func load_resource(mod_path : String, mod:Mod, resource_name:String, internal:bool=true) -> void:
	var tar_dir : String = mod_path + "/" + resource_name + "s"
	var dir : DirAccess = DirAccess.open(tar_dir)
	if !dir:
		#push_warning("No folder was found for %s%s!" % [tar_dir, resource_name])
		return
	dir.list_dir_begin()
	var next : String = dir.get_next()
	while next != "":
		if dir.current_is_dir():
			push_warning("Directory \"%s\" found inside %s folder. This directory is being ignored." % [next, resource_name])
			next = dir.get_next()
			continue
		if next.ends_with(".json"):
			mod.hashing_context.update(FileAccess.get_file_as_bytes(tar_dir + "/" + next))
			var current_file : FileAccess = FileAccess.open(tar_dir + "/" + next, FileAccess.READ)
			load_resource_from_file(current_file, resource_name, mod)
		next = dir.get_next()



func load_resource_from_file(file:FileAccess, resource_name:String, mod:Mod) -> void:
	var JSONData = JSON.new()
	var fileJSON : String = file.get_as_text()
	var error = JSONData.parse(fileJSON)
	if error:
		push_error("JSON Parsing Error in file %s: " % file, JSONData.get_error_message(), " at line ", JSONData.get_error_line(), "\nWhile loading resource %s." % resource_name)
		return
	var data = JSONData.data
	if typeof(data) != TYPE_ARRAY:
		push_error("Json file for resource type: ", resource_name, " does not contain an Array! File name: ", file)
		return
	for resource in data:
		match(resource_name):
			"Attribute": ## Must be loaded: Images, Pscripts
				var new_attr : Attribute = Attribute.new()
				
				new_attr.mod = mod
				new_attr.name = resource["Name"]
				new_attr.desc = resource["Desc"]
				
				new_attr.icon = find_image(resource["Icon"])
				new_attr.pscript = find_resource("Pscript", resource["Pscript"])
				new_attr.type = resource["Type"]
				
				
				var targeting_data : TargetData = TargetData.new()
				targeting_data.allow_burst = resource["AllowBurst"]
				targeting_data.targets = resource["Targets"]
				targeting_data.target_type = resource["TargetType"]
				targeting_data.allowed_metadata = resource["AllowedMetadata"]
				
				new_attr.pscript_sync_data.assign(resource["SyncData"])
				new_attr.pscript = find_resource("Pscript", resource["Pscript"])
				new_attr.duration = resource["Duration"]
				
				var VFX_target = find_resource("VFX", resource["VFX_target"])
				if VFX_target == null:
					new_attr.VFX_target = VFX_null
				var VFX_damage = find_resource("VFX", resource["VFX_damage"])
				if VFX_damage == null:
					new_attr.VFX_target = VFX_null
				
				new_attr.targeting = targeting_data
				
				attributes.append(new_attr)
			"Character": ## Must be loaded: Attributes, Images
				var new_char : Card = Card.new()
				
				new_char.mod = mod
				new_char.type = resource["Type"]
				new_char.name = resource["Name"]
				new_char.full_profile = find_image(resource["FullProfile"])
				new_char.mini_profile = find_image(resource["MiniProfile"])
				new_char.max_health = resource["Health"]
				new_char.defense = resource["Defense"]
				new_char.attack = resource["Attack"]
				new_char.burst = resource["Burst"]
				new_char.heal = resource["Heal"]
				new_char.armor_pierce = resource["ArmorPierce"]
				for atrru in resource["Attributes"]:
					var atri = find_resource("Attribute", atrru)
					if atri != null:
						new_char.attributes.append(atri)
				
				var new_vfx_death = find_resource("VFX", resource["VFX_death"])
				if new_vfx_death == null:
					new_vfx_death = VFX_character_death
				new_char.VFX_death = new_vfx_death
				
				characters.append(new_char)
			"Deck": ## Must be loaded: Everything else
				var new_deck : Deck = Deck.new()
				new_deck.name = resource["Name"]
				var deck_strings : Array[String] = []
				deck_strings.assign(resource["Deck"])
				for component in deck_strings:
					var split := component.split(":", true, 1)
					match(split[0]):
						"Character":
							var chara : Card = find_resource("Character", split[1])
							if chara != null:
								new_deck.characters.append(chara)
						"Item":
							var itm : Item = find_resource("Item", split[1])
							if itm != null:
								new_deck.items.append(itm)
						"Gadget":
							var gdg : Item = find_resource("Item", split[1])
							if gdg != null:
								new_deck.gadgets.append(gdg)
						"Sword":
							var swrd : Item = find_resource("Item", split[1])
							if swrd != null:
								new_deck.sword = swrd
				decks.append(new_deck)
			"Item": ## Must be loaded: Attributes, Images
				var new_item : Item = Item.new()
				new_item.mod = mod
				new_item.name = resource["Name"]
				new_item.desc = resource["Desc"]
				new_item.icon = find_image(resource["Icon"])
				
				new_item.type = resource["Type"]
				new_item.effect = find_resource("Attribute", resource["Effect"])
				
				new_item.uses = resource["Uses"]
				new_item.cost = resource["Cost"]
				
				items.append(new_item)
