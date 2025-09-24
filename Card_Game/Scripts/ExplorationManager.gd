extends Node2D
class_name ExplorationManager

const TILE_SCENE = preload("res://Scenes/Tile.tscn")
const START_BIOME = "plains"        # Starting biome
const TILE_SIZE = Vector2(700, 700)
const START_GRID_SIZE = 3            # 3x3 starting area

var tiles: Array = []
var noise := FastNoiseLite.new()

func _ready():
	# Configure noise
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM # FBM = Fractional Brownian Motion
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.frequency = 0.1
	spawn_starting_area()

# -----------------------------
# Spawn starting 3x3 area
# -----------------------------
func spawn_starting_area():
	for y in range(START_GRID_SIZE):
		for x in range(START_GRID_SIZE):
			var tile: Tile = TILE_SCENE.instantiate()
			add_child(tile)
			tile.grid_pos = Vector2(x, y)
			tile.position = Vector2(x * TILE_SIZE.x, y * TILE_SIZE.y)
			tile.z_index = -1
			tile.set_biome(START_BIOME)
			tile.is_explored = true
			tiles.append(tile)

# -----------------------------
# Generate biome for a new tile
# -----------------------------
func generate_tile_biome(tile: Tile) -> String:
	# --- Base noise ---
	var noise_val = noise.get_noise_2d(tile.grid_pos.x, tile.grid_pos.y)
	noise_val = (noise_val + 1.0) * 0.5  # normalize 0..1
	# --- Base weights ---
	var biome_weights = {
		"forest": 30,
		"plains": 30,
		"desert": 20,
		"mountain": 20
	}

	# --- Adjacency bias ---
	for neighbor in get_adjacent_tiles(tile):
		if neighbor.is_explored:
			match neighbor.biome_type:
				"forest":
					biome_weights["forest"] += 10
				"plains":
					biome_weights["plains"] += 10
				#"desert":
					#biome_weights["desert"] += 5
				#"mountain":
					#biome_weights["mountain"] += 5

	# --- Distance weighting ---
	var start_center = Vector2(START_GRID_SIZE / 2, START_GRID_SIZE / 2)
	var dist = tile.grid_pos.distance_to(start_center)
	biome_weights["desert"] += int(dist * 2)
	biome_weights["mountain"] += int(dist * 1.5)

	# --- Noise influence ---
	if noise_val < 0.3:
		biome_weights["forest"] += 5
		biome_weights["plains"] += 5
	elif noise_val > 0.7:
		biome_weights["desert"] += 5
		biome_weights["mountain"] += 5

	# --- Pick weighted random biome ---
	var total = 0
	for weight in biome_weights.values():
		total += weight

	var pick = randi() % total
	var running = 0
	for biome in biome_weights.keys():
		running += biome_weights[biome]
		if pick < running:
			return biome

	return "plains"  # fallback

# -----------------------------
# Get adjacent tiles (4-directional)
# -----------------------------
func get_adjacent_tiles(tile: Tile) -> Array:
	var neighbors = []
	var offsets = [Vector2(0,-1), Vector2(0,1), Vector2(-1,0), Vector2(1,0)]
	for offset in offsets:
		var pos = tile.grid_pos + offset
		var neighbor = get_tile_at_grid(pos)
		if neighbor:
			neighbors.append(neighbor)
	return neighbors

# -----------------------------
# Retrieve tile at a grid position
# -----------------------------
func get_tile_at_grid(pos: Vector2) -> Tile:
	for t in tiles:
		if t.grid_pos == pos:
			return t
	return null

# -----------------------------
# Reveal a new tile (explore)
# -----------------------------
func reveal_tile(tile: Tile) -> void:
	if tile.is_explored:
		return
	tile.is_explored = true
	var biome = generate_tile_biome(tile)
	tile.set_biome(biome)
	# Optionally add a reveal animation here
