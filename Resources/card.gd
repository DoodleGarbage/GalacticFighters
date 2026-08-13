extends Resource
class_name Card


var mod : Mod

@export var name : String = ""

# The full body art of the character
@export var full_profile : Texture
# A 1:1 aspect (approx 64x64) mugshot of the character
@export var mini_profile : Texture

@export_enum("Special Character", "Character", "Item", "Gadget")
var type : int = 0

@export var max_health : int = 0
#var health : int = 0

@export var defense : int = 0

@export var attack : int = 0

@export var burst : int = 0
@export var heal : int = 0
@export var armor_pierce : int = 0


@export
var attributes : Array[Attribute] = []

var VFX_death : PackedScene
