class_name NpcPathfinder
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]


static func find_path(passable: Dictionary, from: Vector2i, to: Vector2i, maximum_nodes := 2048) -> Array[Vector2i]:
	if from == to:
		return [from]
	var open: Array[Vector2i] = [from]
	var open_set := {from: true}
	var came_from: Dictionary = {}
	var scores := {from: 0}
	var visited := 0
	while not open.is_empty() and visited < maximum_nodes:
		var best_index := 0
		var best := open[0]
		var best_score := int(scores.get(best, 2147483647)) + _distance(best, to)
		for index in range(1, open.size()):
			var candidate := open[index]
			var score := int(scores.get(candidate, 2147483647)) + _distance(candidate, to)
			if score < best_score or (score == best_score and _before(candidate, best)):
				best_index = index
				best = candidate
				best_score = score
		open.remove_at(best_index)
		open_set.erase(best)
		visited += 1
		if best == to:
			return _reconstruct(came_from, to)
		for direction in DIRECTIONS:
			var neighbor := best + direction
			if neighbor != to and neighbor != from and not passable.has(neighbor):
				continue
			var next_score := int(scores[best]) + 1
			if next_score >= int(scores.get(neighbor, 2147483647)):
				continue
			came_from[neighbor] = best
			scores[neighbor] = next_score
			if not open_set.has(neighbor):
				open.append(neighbor)
				open_set[neighbor] = true
	return []


static func _reconstruct(came_from: Dictionary, cursor: Vector2i) -> Array[Vector2i]:
	var reversed: Array[Vector2i] = [cursor]
	while came_from.has(cursor):
		cursor = came_from[cursor] as Vector2i
		reversed.append(cursor)
	reversed.reverse()
	return reversed


static func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
