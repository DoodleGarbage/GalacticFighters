extends Node

func _ready() -> void:
	var test_arr : Array[int] = [1, 2, 3]
	test_arr.insert(0, 6)
	print(test_arr)
	
	var to_sort_array : Array[int] = [3, 6, 4, 2, 0, 1, 1, 8]
	var re_sorted_positions : Array[int] = to_sort_array.duplicate()
	var final_array : Array[int] = []
	while re_sorted_positions.size() > 0:
		var get_lowest : int = get_min(re_sorted_positions)
		final_array.append(re_sorted_positions[get_lowest])
		re_sorted_positions.remove_at(get_lowest)
	print(final_array)

## Returns the index of the lowest in the array
func get_min(array:Array[int]) -> int:
	var lowest : int = 0
	var lowest_value = array[0]
	for i in array.size():
		if array[i] < lowest_value:
			lowest = i
			lowest_value = array[i]
	return lowest
