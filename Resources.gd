extends Node



func _ready() -> void:
	# Load Order: Images, Pscripts, Attributes, SpecialChars
	for internal in [true,false]:
		load_images(internal)
		load_resource("Pscript", internal)
		load_resource("Attribute", internal)
		load_resource("SpecialCharacter", internal)



## Loaded Resources

var attributes : Array[Attribute] = []
var pscripts : Array = []
var characters : Array[Card] = []
var images : Array[Texture] = []



## Resource search functions

func find_resource(resource_type:String, resource_name:String) -> Variant:
	var search_array : Array = []
	match(resource_type):
		"Attribute": search_array = attributes
		"SpecialCharacter", "Character": search_array = characters
		"String":
			return resource_name
		"Images": ## Just an extra way to search for images (redundancy!)
			return find_image(resource_name)
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






## Resource load functions

func load_images(internal:bool = true) -> void:
	var dir_path : String = "res://Data/Image/" if internal else "user://Image/"
	var dir = DirAccess.open(dir_path)
	if !dir:
		push_warning("No folders was found for %sImages!" % dir_path)
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

func load_resource(resource_name:String, internal:bool=true) -> void:
	var tar_dir : String = "res://Data/" if internal else "user://"
	var dir = DirAccess.open(tar_dir + resource_name)
	if !dir:
		push_warning("No folder was found for %s%s!" % [tar_dir, resource_name])
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	## current_file will equal "" if there are no files to be processed left.
	while current_file != "":
		if dir.current_is_dir():
			pass
			#print("Directory \"%s\" found inside %s folder." % [current_file, resource_name])
		else:
			if current_file.ends_with(".json"):
				load_resource_from_file(current_file, resource_name)
		current_file = dir.get_next()


func load_resource_from_file(file:String, resource_name:String) -> void:
	var JSONData = JSON.new()
	## This should never happen.
	if not (FileAccess.file_exists("res://Data/" + resource_name + "/" + file)):
		push_error("File \"%s\" was not found!" % ["res://Data/" + resource_name + "/" + file])
		return
	var File := FileAccess.open("res://Data/" + resource_name + "/" + file, FileAccess.READ)
	var fileJSON : String = File.get_as_text()
	var error = JSONData.parse(fileJSON)
	if error:
		push_error("JSON Parsing Error in file %s: " % file, JSONData.get_error_message(), " at line ", JSONData.get_error_line(), "\nWhile loading resource %s." % resource_name)
		return
	var data = JSONData.data
	if typeof(data) == TYPE_ARRAY:
		for resource in data:
			match(resource_name):
				"Attribute": ## Must be loaded: Images, Pscripts
					var new_attr : Attribute = Attribute.new()
					new_attr.name = resource["Name"]
					new_attr.icon = find_image(resource["Icon"])
					#new_attr.pscript = find_resource("Pscript", resource["Pscript"])
					new_attr.type = resource["Type"]
					new_attr.desc = resource["Desc"]
					attributes.append(new_attr)
				"Pscript":
					## Power scripts must be uniquely loaded due to their nature as scripts
					pass
				"SpecialCharacter", "Character": ## Must be loaded: Attributes, Images
					var new_char : Card = Card.new()
					match(resource_name):
						"SpecialCharacter":
							new_char.type = 0
						"Character":
							new_char.type = 1
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
