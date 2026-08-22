extends Node

## TODO: Move decks to be saved to a user-side .json file (coincides with making the Deck Builder)
## TODO: Save the loaded mods on/off state to a .ini config file on user-side (instead of auto-enabling everything on load)


func _init() -> void:
	var args = Array(OS.get_cmdline_args())
	if args.has("-s"):
		return
	
	for internal in [true,false]:
		init_mods(internal)
	reload_mods(true)
	init_decks()

## Default Resources

const VFX_character_death : PackedScene = preload("res://Data/Vanilla/VFX/death_vfx.tscn")
const VFX_null : PackedScene = preload("res://Data/Vanilla/VFX/null_vfx.tscn")

## Deck Limitations - used to check if a deck should be selectable at battle time or not.

var max_special_characters : int = 1
var max_characters : int = 5
var min_characters : int = 3
var max_gadgets : int = 4
var max_items : int = 10
var min_items : int = 5
var max_swords : int = 1 # not currently functional

func is_deck_valid(deck:Deck) -> bool:
	var special_charas : int = 0
	var charas : int = 0
	for chars in deck.characters:
		if chars.type == 0:
			special_charas += 1
		if chars.type == 1:
			charas += 1
	if (max_special_characters < special_charas 
		or Resources.min_characters > charas 
		or Resources.max_characters < charas
		or Resources.max_gadgets < deck.gadgets.size() 
		or Resources.max_items < deck.items.size() 
		or Resources.min_items > deck.items.size()):
		return false
	return true

func can_deck_load(deck:Array[String]) -> bool:
	var valid : bool = true
	for item in deck:
		var split : PackedStringArray = item.split(":",false,2)
		if split.size() < 3: # Character:mod_name:chara_name <- 3 splits minimum
			continue
		var any_match : bool = false
		for mod in loaded_mods:
			if mod.enabled and mod.name == split[1]:
				any_match = true
		if not any_match:
			valid = false
			break
	print("deck loadability returned: ", valid)
	return valid

## Tracks which mods are considered 'loaded' - TODO: read from a saved "Mod List" .txt file, and automatically add newly loaded mods to it
var loaded_mods : Array[Mod] = []
var loaded_hash : PackedByteArray = []

## Loaded Resources

var attributes : Array[Attribute] = []
var pscripts : Array[GDScript] = [] # PowerScripts, but can't be a typed array
var characters : Array[Card] = []
var items : Array[Item] = []
var decks : Array[Deck] = [] # Holds the user's saved decks
var temp_disabled_decks : Array = [] # All decks are put here then reloaded when reloading mods
var disabled_decks : Array = [] # Holds the unloaded decks that are missing mod dependencies
var vfx : Array[PackedScene] = [] ## Isn't restricted to particle effect nodes to allow for more creative effects, so long as the root node script has a few properties of GPUParticle2D - namely, 'position',  'amount', 'emitting', and signal 'finished'
var images : Array[Texture] = []

func reload_mods(initial:bool=false) -> void:
	temp_disabled_decks = []
	for deck in decks:
		temp_disabled_decks.append([deck.name, Deck.to_str(deck)])
	temp_disabled_decks.append_array(disabled_decks)
	attributes = []
	pscripts = []
	characters = []
	items = []
	decks = []
	disabled_decks = []
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
	if not initial:
		load_decks()


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
	var mod_path : String = "res://Data/" if internal else "user://"
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
				var as_remap : String = get_remapped_path(mod_file)
				#print("as remap mod: ", as_remap)
				if not as_remap.ends_with(".ini") or mod_dir.current_is_dir():
					mod_file = mod_dir.get_next()
					continue
				var mod_file_read := FileAccess.open(mod_path + current_mod + "/" + as_remap, FileAccess.READ)
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

## After loading initial decks, some will be disabled, some will be enabled.
func init_decks() -> void:
	var dir_path : String = "user://"
	var dir = DirAccess.open(dir_path)
	if !dir:
		push_warning("User has no directiory! How!?")
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			current_file = dir.get_next()
			continue
		if current_file.ends_with(".json"):
			var access := FileAccess.open(dir_path + current_file,FileAccess.READ)
			var data_string :String = access.get_line()
			if data_string != "SavedUserDecks":
				current_file = dir.get_next()
				continue
			var mod_file : String = access.get_as_text().trim_prefix(data_string)
			load_resource_from_file(access, "Deck", null, mod_file)
		current_file = dir.get_next()

func load_mod(mod:Mod) -> void:
	mod.hashing_context = HashingContext.new()
	mod.hashing_context.start(HashingContext.HASH_MD5)
	load_images(mod.mod_path, mod, mod.internal)
	load_scene(mod.mod_path, mod, "VFX", mod.internal)
	load_scene(mod.mod_path, mod, "PowerScript", mod.internal)
	load_resource(mod.mod_path, mod, "Attribute", mod.internal)
	load_resource(mod.mod_path, mod, "Character", mod.internal)
	load_resource(mod.mod_path, mod, "Item", mod.internal)
	#load_resource(mod.mod_path, mod, "Deck", mod.internal)
	mod.hash = mod.hashing_context.finish()

func load_decks() -> void:
	for deck in temp_disabled_decks:
		load_resource_data({"Name":deck[0],"Deck":deck[1]}, "Deck")
	temp_disabled_decks = []

func save_decks() -> void:
	var deck_dicts : Array[Dictionary] = []
	for deck in decks:
		deck_dicts.append(Deck.to_dict(deck))
	for dis_deck in disabled_decks:
		deck_dicts.append({"Name":dis_deck[0],"Deck":dis_deck[1]})
	var file : String = "SavedUserDecks\n" + JSON.stringify(deck_dicts)
	var fl_ac := FileAccess.open("user://user_decks.json", FileAccess.WRITE)
	fl_ac.store_string(file)
	fl_ac.close()

func load_images(mod_path:String, mod:Mod, internal:bool) -> void:
	var dir_path : String = mod_path + "/Images"
	var dir = DirAccess.open(dir_path)
	if !dir:
		#push_warning("No folder was found for %s!" % dir_path)
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	while current_file != "":
		print("File in Images: ", current_file)
		if dir.current_is_dir():
			current_file = dir.get_next()
			continue
		var as_remap : String = get_remapped_path_image(current_file)
		if as_remap.ends_with(".png") or as_remap.ends_with(".jpg") or as_remap.ends_with(".jpeg") or as_remap.ends_with(".webp"):
			if internal: ## We need special loading handling if we're loading in res://, as load_from_file will not work on export.
				var new_text : Texture = load(dir_path + "/" + as_remap)
				new_text.resource_name = mod.name + ":" + as_remap.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg").trim_suffix(".webp")
				images.append(new_text)
				current_file = dir.get_next()
				continue
			var new_image : Image = Image.load_from_file(dir_path + as_remap)
			if new_image == null:
				push_error("Found image, but couldn't load it as an image!")
				current_file = dir.get_next()
				continue
			var as_texture = ImageTexture.create_from_image(new_image)
			as_texture.resource_name = mod.name + ":" +  as_remap.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
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
		var as_remap : String = get_remapped_path(next)
		if (resource_type == "PowerScript" and not as_remap.ends_with(".gd")) or (resource_type == "VFX" and not as_remap.ends_with(".tscn")):
			#push_warning("There is an incorrect file type for %s in directory. File: %s" % [resource_type, directory + next])
			next = dir.get_next()
			continue
		var new_scene = load(directory + "/" + as_remap)
		new_scene.resource_name = mod.name + ":" + as_remap.trim_suffix(".gd").trim_suffix(".tscn")
		match(resource_type):
			"VFX": vfx.append(new_scene)
			"PowerScript": 
				#mod.hashing_context.update(FileAccess.get_file_as_bytes(directory + "/" + next))
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
		var as_remap : String = get_remapped_path(next)
		if as_remap.ends_with(".json"):
			mod.hashing_context.update(FileAccess.get_file_as_bytes(tar_dir + "/" + next))
			var current_file : FileAccess = FileAccess.open(tar_dir + "/" + as_remap, FileAccess.READ)
			load_resource_from_file(current_file, resource_name, mod)
		next = dir.get_next()



func load_resource_from_file(file:FileAccess, resource_name:String, mod:Mod, modified_file:String="") -> void:
	var JSONData = JSON.new()
	var fileJSON : String = file.get_as_text() if modified_file == "" else modified_file
	var error = JSONData.parse(fileJSON)
	if error:
		push_error("JSON Parsing Error in file %s: " % file, JSONData.get_error_message(), " at line ", JSONData.get_error_line(), "\nWhile loading resource %s." % resource_name)
		return
	var data = JSONData.data
	if typeof(data) != TYPE_ARRAY:
		push_error("Json file for resource type: ", resource_name, " does not contain an Array! File name: ", file)
		return
	for resource in data:
		load_resource_data(resource, resource_name, mod)

func load_resource_data(resource:Dictionary, resource_name:String, mod:Mod=null) -> void:
	match(resource_name):
		"Attribute": ## Must be loaded: Images, Pscripts
			var new_attr : Attribute = Attribute.new()
			new_attr.mod = mod
			new_attr.name = resource.get_or_add("Name", "")
			new_attr.desc = resource.get_or_add("Desc", "")
			
			new_attr.icon = find_image(resource.get_or_add("Icon", ""))
			new_attr.pscript = find_resource("Pscript", resource.get_or_add("Pscript", ""))
			new_attr.script_variables = resource.get_or_add("ScriptVariables", {})
			new_attr.type = resource.get_or_add("Type", 0)
			
			new_attr.interaction_type = resource.get_or_add("InteractionType", "")
			
			var targeting_data : TargetData = TargetData.new()
			targeting_data.allow_burst = resource.get_or_add("AllowBurst", false)
			targeting_data.targets = resource.get_or_add("Targets", -1)
			targeting_data.target_type = resource.get_or_add("TargetType", 0)
			targeting_data.allowed_metadata = resource.get_or_add("AllowedMetadata", 1)
			
			new_attr.pscript_sync_data.assign(resource.get_or_add("SyncData", []))
			new_attr.pscript = find_resource("Pscript", resource.get_or_add("Pscript", ""))
			new_attr.duration = resource.get_or_add("Duration", -1)
			new_attr.application_behavior = resource.get_or_add("ApplicationBehavior", 0)
			
			new_attr.modified_stats.assign(resource.get_or_add("StatModifiers", [0,0,0,0,0,0]))
			
			var VFX_target = find_resource("VFX", resource.get_or_add("VFX_target", ""))
			if VFX_target == null:
				new_attr.VFX_target = VFX_null
			var VFX_damage = find_resource("VFX", resource.get_or_add("VFX_damage", ""))
			if VFX_damage == null:
				new_attr.VFX_target = VFX_null
			
			new_attr.targeting = targeting_data
			
			attributes.append(new_attr)
		"Character": ## Must be loaded: Attributes, Images
			var new_char : Card = Card.new()
			
			new_char.mod = mod
			new_char.type = resource.get_or_add("Type", 0)
			new_char.name = resource.get_or_add("Name", "")
			new_char.full_profile = find_image(resource.get_or_add("FullProfile",""))
			new_char.mini_profile = find_image(resource.get_or_add("MiniProfile",""))
			new_char.max_health = resource.get_or_add("Health", 1)
			new_char.defense = resource.get_or_add("Defense", 0)
			new_char.attack = resource.get_or_add("Attack", 0)
			new_char.burst = resource.get_or_add("Burst", 0)
			new_char.heal = resource.get_or_add("Heal", 0)
			new_char.armor_pierce = resource.get_or_add("ArmorPierce", 0)
			for atrru in resource.get_or_add("Attributes",[]):
				var atri = find_resource("Attribute", atrru)
				if atri != null:
					new_char.attributes.append(atri)
			
			var new_vfx_death = find_resource("VFX", resource.get_or_add("VFX_death", ""))
			if new_vfx_death == null:
				new_vfx_death = VFX_character_death
			new_char.VFX_death = new_vfx_death
			
			characters.append(new_char)
		"Deck": ## Must be loaded: Everything else
			for deck in decks:
				if deck.name == resource.get_or_add("Name", ""):
					push_warning("Deck naming conflict, skipping. (Name: %s)" % deck.name)
					return
			var new_deck : Deck = Deck.new()
			new_deck.name = resource.get_or_add("Name", "")
			var deck_strings : Array[String] = []
			deck_strings.assign(resource.get_or_add("Deck", []))
			var continue_loading : bool = can_deck_load(deck_strings)
			if not continue_loading: # A mod that this deck depends on isn't loaded, so we can't load this deck
				print("Deck failed the mod loading check")
				disabled_decks.append([resource.get_or_add("Name", ""), deck_strings]) # We stow it away since we don't want to delete the deck when we save over the saved decks file.
				return
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
			if new_deck.is_empty(): # skip over empty decks
				return
			decks.append(new_deck)
		"Item": ## Must be loaded: Attributes, Images
			var new_item : Item = Item.new()
			new_item.mod = mod
			new_item.name = resource.get_or_add("Name", "")
			new_item.desc = resource.get_or_add("Desc", "")
			new_item.icon = find_image(resource.get_or_add("Icon", ""))
			
			new_item.type = resource.get_or_add("Type", 0)
			new_item.effect = find_resource("Attribute", resource.get_or_add("Effect", ""))
			
			new_item.uses = resource.get_or_add("Uses", -1)
			new_item.cost = resource.get_or_add("Cost", 0)
			
			items.append(new_item)


static func get_remapped_path(path : String) -> String:
	if OS.has_feature("export"):
		# Check if file is .remap
		if not path.ends_with(".remap"):
			#print("returned path, no .remap")q
			return path
		return path.trim_suffix(".remap")
		# Open the file
		#var __config_file = ConfigFile.new()
		#__config_file.load(path)
		## Load the remapped file
		#var __remapped_file_path = __config_file.get_value("remap", "path")
		#__config_file = null
		#print("We found a .remap, result: ", __remapped_file_path)
		#return __remapped_file_path
	else:
		return path

static func get_remapped_path_image(path : String) -> String:
	if OS.has_feature("export"):
		# Check if file is .remap
		if not path.ends_with(".remap"):
			#print("returned path, no .remap")q
			return path.trim_suffix(".import")
		# Open the file
		var __config_file = ConfigFile.new()
		__config_file.load(path)
		# Load the remapped file
		var __remapped_file_path = __config_file.get_value("remap", "path")
		__config_file = null
		print("We found a .remap, result: ", __remapped_file_path)
		return __remapped_file_path
	else:
		return path
