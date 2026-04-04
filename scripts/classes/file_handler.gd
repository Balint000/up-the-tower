class_name FileHandler
extends Node

static func store_json_file(data: Dictionary, file_path: String, create_dir: bool) -> Error:
	var result: Array = _open_file_for_write(file_path, create_dir)
	var err: Error = result[0] as Error
	var file: FileAccess = result[1] as FileAccess
	
	if err != OK:
		return err
	
	file.store_string(JSON.stringify(data))
	file.close()
	return OK

static func _open_file_for_write(file_path: String, create_dir: bool) -> Array:
	var err: Error = _check_and_create_directory(file_path, create_dir)
	if err != OK:
		return [err, null]
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return [FileAccess.get_open_error(), null]
	
	return [OK, file]

static func _open_file_for_read(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return [ERR_FILE_NOT_FOUND, null]
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return [FileAccess.get_open_error(), null]
	
	return [OK, file]

static func _check_and_create_directory(file_path: String, create: bool) -> Error:
	var dir_path: String = file_path.get_base_dir()
	if DirAccess.dir_exists_absolute(dir_path):
		return OK
	if not create:
		return ERR_CANT_CREATE
	
	return DirAccess.make_dir_recursive_absolute(dir_path)

static func open_json_file(file_path: String, out_data: Dictionary) -> Error:
	out_data.clear()
	
	var result: Array = _open_file_for_read(file_path)
	var err: Error = result[0] as Error
	var file: FileAccess = result[1] as FileAccess
	
	if err != OK:
		return err
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	err = json.parse(json_string)
	if err != OK:
		return err
	
	var json_data: Variant = json.get_data()
	if typeof(json_data) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA
	
	out_data.merge(json_data as Dictionary, true)
	return OK
