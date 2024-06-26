extends Node2D

@export var number_wave = 1
@export var length_range = Vector2(1.0 / 500.0, 1.0 / 50.0)
@export var angle_range = Vector2(0, 2 * PI)
@export var zero_phase_range = Vector2(- 1.0 / 50.0, 1.0 / 50.0)
@export var speed = 1.0 / 2.0

var phase = 0

var num_tiles = 0
var all_parameters = []
var cell_size = 0
var needed_tiles = []
var atlas_col_num = 0

var tilemap
var precalc_vec = []

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	print(number_wave)
	# get info on tiles (number, size and how many needed for our window)
	tilemap = get_node("PlasmaTiles")
	
	var tileset = tilemap.get_tileset()
	
	# godot 4 has changed a lot of things... 
	num_tiles = tileset.get_source(0).get_tiles_count()
	#print("Using " + str(num_tiles) + " tiles")
	
	# why is this so convoluted to work out the shape of the atlas
	atlas_col_num = tileset.get_source(0).get_tile_id(num_tiles-1).x + 1
	
	cell_size = tileset.get_tile_size()[0]
	#print("Tile Size = " + str(cell_size))
	
	var window_size = get_window().get_size()
	needed_tiles = [floor(window_size[0] / cell_size) + 1, floor(window_size[1] / cell_size) + 1]
	#print("Number of required tiles = " + str(needed_tiles))
	
	# first generate waves parameters
	all_parameters.clear()
	all_parameters.resize(number_wave)
	_generate_all_parameters()
	#print("Done generating")


func _generate_all_parameters():
	#print("Regenerating All")
	# generate all waves parameters
	all_parameters.clear()
	for _i in range(number_wave):
		all_parameters += [_generate_wave_parameters()]
	_generate_all_precalculated_vector()


func _generate_one_parameters():
	var x = range(number_wave)
	x.shuffle()
	var param_ref = x[0]
	#print("Regenerating wave number " + str(param_ref))
	all_parameters[param_ref] = _generate_wave_parameters()
	_generate_all_precalculated_vector()


func _generate_wave_parameters():
	# we had length, angle (converted to vector) and phase
	var angle = randf_range(angle_range.x, angle_range.y)
	var wave_param = [randf_range(length_range.x, length_range.y), 
					 [cos(angle), sin(angle)],
					 randf_range(zero_phase_range.x, zero_phase_range.y)]
	return wave_param


func _generate_all_precalculated_vector():
	# pre-generate the vector for the phase
	precalc_vec = []
	var vecx
	var vecy
	var val
	for row in needed_tiles[1]:
		var row_pos = []
		var row_precalc = []
		for col in needed_tiles[0]:
			row_pos = [(col + 0.5) * cell_size, (row + 0.5) * cell_size]
			vecx = 0
			vecy = 0
			for params in all_parameters:
				val = params[0] * (row_pos[0] * params[1][0] + 
					  row_pos[1] * params[1][1]) + params[2]
				vecx += sin(val)
				vecy += cos(val)
			row_precalc += [[vecx, vecy]]
		precalc_vec += [row_precalc]


func _process(delta):
	# this is where we update the tilemap
	
	## if we press space - we reset all the waves
	#if Input.is_physical_key_pressed(KEY_SPACE):
		#_generate_all_parameters()
	#
	var val
	var phase_trig = [cos(phase), sin(phase)]
	var atl_pos = Vector2i(0, 0)
	
	for row in range(needed_tiles[1]):
		for col in range(needed_tiles[0]):
			val = precalc_vec[row][col][0] * phase_trig[0] + precalc_vec[row][col][1] * phase_trig[1]
			val += number_wave
			val *= (num_tiles - 1) / (2.0 * number_wave)
			val = int(floor(val) + 1)
			
			# set the tile
			atl_pos = Vector2i(val % atlas_col_num, val / atlas_col_num)
			tilemap.set_cell(0, Vector2i(col, row), 0, atl_pos, 0)

	# update the phase
	var phase_shift = speed * delta
	phase += phase_shift


func _on_Timer_timeout():
	# need to autostart / start the timer
	call_deferred("_generate_one_parameters")
