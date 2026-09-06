class_name WorldEventPlanner
extends RefCounted

const COPRIME_STEPS := [1, 3, 5, 7]

var _world_seed := 0
var _catalog: WorldEventCatalog
var _offset := 0
var _step := 1


func _init(world_seed: int, catalog := WorldEventCatalog.new()) -> void:
	_world_seed = world_seed
	_catalog = catalog
	var event_count := maxi(1, _catalog.event_ids().size())
	var stable := WorldSeed.from_text("%d|world-event-schedule|v1" % _world_seed)
	_offset = int(stable % event_count)
	_step = COPRIME_STEPS[int((stable >> 8) % COPRIME_STEPS.size())]


func plan_for_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or not _catalog.is_valid():
		return {}
	var ids := _catalog.event_ids()
	var event_id := ids[posmod(_offset + slot_index * _step, ids.size())]
	var definition := _catalog.event(event_id)
	var start_seconds := _catalog.first_event_seconds() + float(slot_index) * _catalog.event_interval_seconds()
	var end_seconds := start_seconds + float(definition["duration_seconds"])
	return {
		"slot_index": slot_index,
		"instance_id": "world-event:%d:%s" % [slot_index, event_id],
		"event_id": String(event_id),
		"start_seconds": start_seconds,
		"end_seconds": end_seconds,
		"day": int(floor(start_seconds / _catalog.day_seconds())) + 1,
		"hour": fposmod(start_seconds, _catalog.day_seconds()) / _catalog.day_seconds() * 24.0,
		"display_name": String(definition["display_name"]),
		"description": String(definition["description"]),
		"category": String(definition["category"]),
	}


func timetable(start_slot: int, count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_index in range(maxi(0, start_slot), maxi(0, start_slot) + maxi(0, count)):
		result.append(plan_for_slot(slot_index))
	return result


func slot_at_or_before(total_seconds: float) -> int:
	if total_seconds < _catalog.first_event_seconds():
		return -1
	return floori((total_seconds - _catalog.first_event_seconds()) / _catalog.event_interval_seconds())
