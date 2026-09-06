class_name HydrologyGenerator
extends RefCounted

enum Feature { NONE, RIVER, LAKE, ICE_LAKE, OASIS, BANK, BRIDGE }

const RIVER_HALF_WIDTH := 0.018
const BANK_HALF_WIDTH := 0.038

var _world_seed: int
var _channel_noise := FastNoiseLite.new()
var _basin_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _init(world_seed: int) -> void:
	_world_seed = world_seed
	_configure(_channel_noise, &"river_channel", 0.006, 3)
	_configure(_basin_noise, &"lake_basin", 0.0035, 3)
	_configure(_detail_noise, &"water_detail", 0.021, 2)


func feature_at(world_tile: Vector2i, terrain: ChunkData.Terrain, biome_id: StringName, temperature: float, elevation: float) -> Feature:
	if terrain != ChunkData.Terrain.LAND:
		return Feature.NONE
	var basin := _normalized(_basin_noise, world_tile)
	var detail := _normalized(_detail_noise, world_tile)
	if biome_id == &"desert" and temperature >= 0.48 and basin < 0.30 and detail > 0.58:
		return Feature.OASIS
	if basin < 0.25 and elevation < 0.72:
		return Feature.ICE_LAKE if temperature < 0.28 else Feature.LAKE
	var channel_distance := absf(_normalized(_channel_noise, world_tile) - 0.5)
	if channel_distance <= RIVER_HALF_WIDTH and elevation > 0.42 and elevation < 0.82:
		if _is_bridge(world_tile):
			return Feature.BRIDGE
		return Feature.RIVER
	if channel_distance <= BANK_HALF_WIDTH and elevation > 0.40 and elevation < 0.84:
		return Feature.BANK
	return Feature.NONE


static func is_water(feature: Feature) -> bool:
	return feature == Feature.RIVER or feature == Feature.LAKE or feature == Feature.ICE_LAKE or feature == Feature.OASIS


static func movement_multiplier(feature: Feature) -> float:
	match feature:
		Feature.RIVER, Feature.OASIS:
			return 0.62
		Feature.LAKE:
			return 0.48
		Feature.ICE_LAKE:
			return 0.82
		_:
			return 1.0


func _is_bridge(world_tile: Vector2i) -> bool:
	var along := world_tile.x + world_tile.y
	var phase := posmod(WorldSeed.to_noise_seed(WorldSeed.derive(_world_seed, &"bridge_phase")), 37)
	return posmod(along + phase, 37) <= 2


func _configure(noise: FastNoiseLite, domain: StringName, frequency: float, octaves: int) -> void:
	noise.seed = WorldSeed.to_noise_seed(WorldSeed.derive(_world_seed, domain))
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5


func _normalized(noise: FastNoiseLite, world_tile: Vector2i) -> float:
	return noise.get_noise_2d(world_tile.x, world_tile.y) * 0.5 + 0.5
