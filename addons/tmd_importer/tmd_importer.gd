@tool
extends EditorImportPlugin

enum Presets {}

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return []


func _get_import_order() -> int:
	return 0


func _get_importer_name() -> String:
	return "tmd.importer"


func _get_preset_count() -> int:
	return Presets.size()


func _get_priority() -> float:
	return 1.0


func _get_recognized_extensions() -> PackedStringArray:
	return ["tmd"]


func _get_resource_type() -> String:
	return "ArrayMesh"


func _get_save_extension() -> String:
	return "mesh"


func _get_visible_name() -> String:
	return "TMD Importer"


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var bytes := FileAccess.get_file_as_bytes(source_file)
	var tmd := TMD.create_from_bytes(bytes)
	var array_mesh: ArrayMesh = tmd.to_array_mesh()
	var error := ResourceSaver.save(array_mesh, "%s.%s" % [save_path, _get_save_extension()], ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		print_debug(error_string(error))
	return error
