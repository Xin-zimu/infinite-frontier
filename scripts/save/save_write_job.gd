class_name SaveWriteJob
extends RefCounted

const MAX_BACKUPS := 5

var snapshot: Dictionary
var result: Dictionary = {}
var worker_task_id := -1


func _init(save_snapshot: Dictionary) -> void:
	snapshot = save_snapshot.duplicate(true)


func execute() -> void:
	worker_task_id = WorkerThreadPool.get_caller_task_id()
	var started_usec := Time.get_ticks_usec()
	var root_path := String(snapshot["root_path"])
	var chunks_root := root_path.path_join("chunks")
	var surface_chunks_path := chunks_root.path_join("surface")
	var underground_chunks_path := chunks_root.path_join("underground")
	var backups_path := root_path.path_join("backups")
	var error := DirAccess.make_dir_recursive_absolute(surface_chunks_path)
	if error != OK:
		_fail("无法创建区块差异目录：%s" % error_string(error), started_usec)
		return
	error = DirAccess.make_dir_recursive_absolute(underground_chunks_path)
	if error != OK:
		_fail("无法创建地下区块差异目录：%s" % error_string(error), started_usec)
		return
	error = DirAccess.make_dir_recursive_absolute(backups_path)
	if error != OK:
		_fail("无法创建备份目录：%s" % error_string(error), started_usec)
		return
	var backup_path := ""
	if bool(snapshot.get("create_backup", false)):
		var backup_result := _backup_current(root_path, chunks_root, backups_path)
		if not bool(backup_result["ok"]):
			_fail(String(backup_result["error"]), started_usec)
			return
		backup_path = String(backup_result["path"])
	var world_result := _write_json_atomic(root_path.path_join("world.json"), snapshot["world"] as Dictionary)
	if not bool(world_result["ok"]):
		_fail(String(world_result["error"]), started_usec)
		return
	var player_result := _write_json_atomic(root_path.path_join("player.json"), snapshot["player"] as Dictionary)
	if not bool(player_result["ok"]):
		_fail(String(player_result["error"]), started_usec)
		return
	var written_differences := 0
	var differences := snapshot.get("chunk_differences", {}) as Dictionary
	var retained_files := {"surface": {}, "underground": {}}
	for chunk_key_value in differences.keys():
		var chunk_key := String(chunk_key_value)
		var difference := differences[chunk_key] as Dictionary
		var layer := String(difference.get("layer", "surface"))
		var layer_path := underground_chunks_path if layer == "underground" else surface_chunks_path
		var filename := chunk_key.trim_prefix(layer + "_") + ".json"
		(retained_files[layer] as Dictionary)[filename] = true
		var write_result := _write_json_atomic(layer_path.path_join(filename), difference)
		if not bool(write_result["ok"]):
			_fail(String(write_result["error"]), started_usec)
			return
		written_differences += 1
	var cleanup_error := _remove_stale_difference_files(surface_chunks_path, retained_files["surface"] as Dictionary)
	if not cleanup_error.is_empty():
		_fail(cleanup_error, started_usec)
		return
	cleanup_error = _remove_stale_difference_files(underground_chunks_path, retained_files["underground"] as Dictionary)
	if not cleanup_error.is_empty():
		_fail(cleanup_error, started_usec)
		return
	_cleanup_old_backups(backups_path)
	result = {
		"ok": true,
		"error": "",
		"duration_usec": Time.get_ticks_usec() - started_usec,
		"written_difference_files": written_differences,
		"backup_path": backup_path,
	}


func _backup_current(root_path: String, chunks_root: String, backups_path: String) -> Dictionary:
	var suffix := int(Time.get_ticks_usec() % 1000000)
	var backup_name := "backup-%d-%06d" % [int(Time.get_unix_time_from_system()), suffix]
	var backup_path := backups_path.path_join(backup_name)
	var error := DirAccess.make_dir_recursive_absolute(backup_path.path_join("chunks/surface"))
	if error != OK:
		return {"ok": false, "error": "无法创建存档备份：%s" % error_string(error), "path": ""}
	error = DirAccess.make_dir_recursive_absolute(backup_path.path_join("chunks/underground"))
	if error != OK:
		return {"ok": false, "error": "无法创建地下存档备份：%s" % error_string(error), "path": ""}
	for filename in ["world.json", "player.json"]:
		var source := root_path.path_join(filename)
		if not FileAccess.file_exists(source):
			continue
		var copy_result := _copy_file(source, backup_path.path_join(filename))
		if not bool(copy_result["ok"]):
			return copy_result
	for layer in ["surface", "underground"]:
		var chunks_path := chunks_root.path_join(layer)
		var directory := DirAccess.open(chunks_path)
		if directory == null:
			continue
		for filename in directory.get_files():
			if not filename.ends_with(".json"):
				continue
			var copy_result := _copy_file(chunks_path.path_join(filename), backup_path.path_join("chunks").path_join(layer).path_join(filename))
			if not bool(copy_result["ok"]):
				return copy_result
	return {"ok": true, "error": "", "path": backup_path}


func _copy_file(source: String, target: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(source)
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "无法写入备份文件 %s：%s" % [target, error_string(FileAccess.get_open_error())], "path": ""}
	file.store_buffer(bytes)
	file.flush()
	return {"ok": true, "error": "", "path": target}


func _remove_stale_difference_files(layer_path: String, retained: Dictionary) -> String:
	var directory := DirAccess.open(layer_path)
	if directory == null:
		return "无法读取区块差异目录：%s" % layer_path
	for filename in directory.get_files():
		if not filename.ends_with(".json") or retained.has(filename):
			continue
		var error := DirAccess.remove_absolute(layer_path.path_join(filename))
		if error != OK:
			return "无法清理过期区块差异 %s：%s" % [filename, error_string(error)]
	return ""


func _write_json_atomic(path: String, data: Dictionary) -> Dictionary:
	var temporary_path := "%s.tmp" % path
	var previous_path := "%s.previous" % path
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "无法创建临时存档 %s：%s" % [temporary_path, error_string(FileAccess.get_open_error())]}
	file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
	file.flush()
	file = null
	if FileAccess.file_exists(previous_path):
		var cleanup_error := DirAccess.remove_absolute(previous_path)
		if cleanup_error != OK:
			return {"ok": false, "error": "无法清理旧的存档事务文件：%s" % error_string(cleanup_error)}
	var had_existing := FileAccess.file_exists(path)
	if had_existing:
		var move_old_error := DirAccess.rename_absolute(path, previous_path)
		if move_old_error != OK:
			return {"ok": false, "error": "无法保护旧存档 %s：%s" % [path, error_string(move_old_error)]}
	var commit_error := DirAccess.rename_absolute(temporary_path, path)
	if commit_error != OK:
		if had_existing and FileAccess.file_exists(previous_path):
			DirAccess.rename_absolute(previous_path, path)
		return {"ok": false, "error": "无法提交存档 %s：%s" % [path, error_string(commit_error)]}
	if had_existing and FileAccess.file_exists(previous_path):
		DirAccess.remove_absolute(previous_path)
	return {"ok": true, "error": ""}


func _cleanup_old_backups(backups_path: String) -> void:
	var directory := DirAccess.open(backups_path)
	if directory == null:
		return
	var directories: Array[String] = []
	for dirname in directory.get_directories():
		directories.append(dirname)
	directories.sort()
	while directories.size() > MAX_BACKUPS:
		var oldest := String(directories.pop_front())
		_remove_backup_tree(backups_path.path_join(oldest), backups_path)


func _remove_backup_tree(path: String, backups_root: String) -> void:
	if not path.begins_with(backups_root + "/"):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(path.path_join(filename))
	for dirname in directory.get_directories():
		_remove_backup_tree(path.path_join(dirname), backups_root)
	DirAccess.remove_absolute(path)


func _fail(message: String, started_usec: int) -> void:
	result = {
		"ok": false,
		"error": message,
		"duration_usec": Time.get_ticks_usec() - started_usec,
		"written_difference_files": 0,
		"backup_path": "",
	}
