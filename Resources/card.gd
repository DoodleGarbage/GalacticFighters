extends Resource
class_name Card

@export
var name : String = ""

@export_enum("Special Character", "Character", "Item", "Gadget")
var type : int = 0

@export
var attributes : Array[Attribute] = []

@export
var abilities : Array[Ability] = []

var statuses : Array[Status] = []
