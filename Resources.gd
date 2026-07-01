extends Node




func _init() -> void:
	# Load Order: Images, Pscripts, Attributes, SpecialChars
	for internal in [true,false]:
		load_images(internal)
		load_powerscripts(internal)
		load_resource("Attribute", internal)
		load_resource("Character", internal)
		load_resource("Deck", internal)



## Loaded Resources

var attributes : Array[Attribute] = []
var pscripts : Array[GDScript] = [] # PowerScripts, but can't be a typed array
var characters : Array[Card] = []
var decks : Array[Deck] = []
var images : Array[Texture] = []



## Resource search functions

func find_resource(resource_type:String, resource_name:String) -> Variant:
	var search_array : Array = []
	match(resource_type):
		"Attribute": search_array = attributes
		"Character": search_array = characters
		"Deck": search_array = decks
		"String":
			return resource_name
		"Images": ## Just an extra way to search for images (redundancy! or bloat...)
			return find_image(resource_name)
		"Pscript":
			return find_pscript(resource_name)
		_: push_error("Resource array for resource type %s does not exist!" % resource_type); return
	for resource in search_array:
		if resource.name == resource_name:
			return resource
	push_warning("Could not find resource of type %s for name \"%s\"!" % [resource_type, resource_name])
	return null

func find_image(imagename:String) -> Texture:
	for image : Texture in images:
		if image.resource_name == imagename:
			return image
	return null

## For some reason, script must return as GDscript and cannot be an extending type (PowerScript)
func find_pscript(scriptname:String) -> GDScript:
	for script in pscripts:
		if script.resource_name == scriptname:
			return script
	return null




## Resource load functions

func load_images(internal:bool = true) -> void:
	var dir_path : String = "res://Data/Image/" if internal else "user://Image/"
	var dir = DirAccess.open(dir_path)
	if !dir:
		push_warning("No folders was found for %s!" % dir_path)
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			pass
		elif current_file.ends_with(".png") or current_file.ends_with(".jpg") or current_file.ends_with(".jpeg"):
			if internal: ## We need special loading handling if we're loading in res://, as load_from_file will not work on export.
				var new_text : Texture = load(dir_path + current_file)
				new_text.resource_name = current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
				images.append(new_text)
				current_file = dir.get_next()
				continue
			var new_image : Image = Image.load_from_file(dir_path + current_file)
			if new_image == null:
				push_error("Found image, but couldn't load it as an image!")
				current_file = dir.get_next()
				continue
			var as_texture = ImageTexture.create_from_image(new_image)
			as_texture.resource_name = current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
			images.append(as_texture)
		current_file= dir.get_next()
	return

func load_powerscripts(internal:bool=true) -> void:
	var directory : String = "res://Data/Pscript/" if internal else "user://Pscript/"
	var dir : DirAccess = DirAccess.open(directory)
	if !dir:
		push_warning("No folder was found for Powerscript: %s" % [directory])
		return
	dir.list_dir_begin()
	var next : String = dir.get_next()
	while next != "":
		if dir.current_is_dir():
			push_warning("Directory \"%s\" found inside %s folder. This directory is being ignored." % [next, directory])
			next = dir.get_next()
			continue
		if not next.ends_with(".gd"):
			push_warning("There is a non-.gd file in the Powerscript directory. File: %s" % [directory + next])
			next = dir.get_next()
			continue
		var new_pscript = load(directory + next)
		new_pscript.resource_name = next.trim_suffix(".gd")
		pscripts.append(new_pscript)
		next = dir.get_next()
	return

func load_resource(resource_name:String, internal:bool=true) -> void:
	var tar_dir : String = "res://Data/" if internal else "user://"
	var dir : DirAccess = DirAccess.open(tar_dir + resource_name)
	if !dir:
		push_warning("No folder was found for %s%s!" % [tar_dir, resource_name])
		return
	dir.list_dir_begin()
	var next : String = dir.get_next()
	while next != "":
		if dir.current_is_dir():
			push_warning("Directory \"%s\" found inside %s folder. This directory is being ignored." % [next, resource_name])
			next = dir.get_next()
			continue
		if next.ends_with(".json"):
			var current_file : FileAccess = FileAccess.open(tar_dir + resource_name + "/" + next, FileAccess.READ)
			load_resource_from_file(current_file, resource_name)
		next = dir.get_next()



func load_resource_from_file(file:FileAccess, resource_name:String) -> void:
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
				new_attr.name = resource["Name"]
				
				new_attr.icon = find_image(resource["Icon"])
				new_attr.pscript = find_resource("Pscript", resource["Pscript"])
				new_attr.type = resource["Type"]
				new_attr.desc = resource["Desc"]
				new_attr.allow_burst = resource["AllowBurst"]
				new_attr.targets = resource["Targets"]
				new_attr.target_type = resource["TargetType"]
				new_attr.allowed_metadata = resource["AllowedMetadata"]
				new_attr.pscript_sync_data.assign(resource["SyncData"])
				new_attr.pscript = find_resource("Pscript", resource["Pscript"])
				new_attr.duration = resource["Duration"]
				attributes.append(new_attr)
			"Pscript":
				## Power scripts must be uniquely loaded due to their nature as scripts
				pass
			"Character": ## Must be loaded: Attributes, Images
				var new_char : Card = Card.new()
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
				characters.append(new_char)
			"Deck": ## Must be loaded: Everything else
				var new_deck : Deck = Deck.new()
				new_deck.name = resource["name"]
				var deck_strings : Array[String] = []
				deck_strings.assign(resource["deck"])
				for component in deck_strings:
					var split := component.split(":", true, 1)
					match(split[0]):
						"Character":
							var chara : Card = find_resource("Character", split[1])
							if chara != null:
								new_deck.characters.append(chara)
						"Item", "Gadget", "Sword":
							push_warning("loading deck that has ", split[0], ". Ignoring.")
				decks.append(new_deck)
