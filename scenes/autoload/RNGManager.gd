extends Node
class_name RNGManager

var rng := RandomNumberGenerator.new()

func _ready():
	# Optionally auto-seed with a time-based seed:
	var randint = randi()
	print(randint)
	seed_random(1318924097)

func seed_random(seed: int):
	rng.seed = seed

func get_random_int(min_val: int, max_val: int) -> int:
	return rng.randi_range(min_val, max_val)

func get_random_float() -> float:
	return rng.randf()

func get_random_element(array: Array):
	if array.size() == 0:
		return null
	return array[rng.randi_range(0, array.size() - 1)]

func array_shuffle(array):
	for i in array.size():
		var rand_idx = get_random_int(0,array.size()-1)
		if rand_idx == i:
			pass
		else:
			var temp = array[rand_idx]
			array[rand_idx] = array[i]
			array[i] = temp
	return array
