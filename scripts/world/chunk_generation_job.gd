class_name ChunkGenerationJob
extends RefCounted

var world_seed: int
var chunk_position: Vector2i
var world_layer: StringName
var dungeon_id := ""
var dungeon_anchor_chunk := Vector2i.ZERO
var result: ChunkData
var worker_task_id := -1


func _init(seed: int, coordinate: Vector2i, layer: StringName = &"surface", next_dungeon_id := "", next_dungeon_anchor := Vector2i.ZERO) -> void:
	world_seed = seed
	chunk_position = coordinate
	world_layer = layer
	dungeon_id = next_dungeon_id
	dungeon_anchor_chunk = next_dungeon_anchor


func execute() -> void:
	worker_task_id = WorkerThreadPool.get_caller_task_id()
	if world_layer == &"dungeon":
		result = DungeonGenerator.new(world_seed, dungeon_id, dungeon_anchor_chunk).generate_chunk(chunk_position)
	elif world_layer == &"underground":
		result = CaveGenerator.new(world_seed).generate_chunk(chunk_position)
	else:
		result = TerrainGenerator.new(world_seed).generate_chunk(chunk_position, world_layer)
