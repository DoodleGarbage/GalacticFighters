extends Resource
class_name Card

@export
var name : String = ""

@export_enum("Special Character", "Character", "Item", "Gadget")
var type : int = 0

@export
var max_health : int = 0
var health : int = 0

@export
var defense : int = 0

@export
var attack : int = 0

@export
var burst : int = 0
@export
var heal : int = 0
@export
var armor_pierce : int = 0


@export
var attributes : Array[Attribute] = []

var statuses : Array[Attribute] = []
