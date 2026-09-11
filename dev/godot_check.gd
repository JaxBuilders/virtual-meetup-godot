extends SceneTree

const ROOTS := [
	"res://scripts",
	"res://scenes",
	"res://resources",
]
const EXTENSIONS := ["gd", "tscn", "tres"]


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	var paths := PackedStringArray()
	for root in ROOTS:
		_collect_paths(root, paths)
	paths.sort()

	var failures := PackedStringArray()
	var loaded_count := 0
	for resource_path in paths:
		var resource := ResourceLoader.load(
			resource_path,
			"",
			ResourceLoader.CACHE_MODE_IGNORE
		)
		if resource == null:
			failures.append(resource_path)
		elif resource is Script and not (resource as Script).can_instantiate():
			failures.append(resource_path)
		elif resource is PackedScene:
			var instance := (resource as PackedScene).instantiate()
			if instance == null:
				failures.append(resource_path)
			else:
				instance.free()
				loaded_count += 1
		else:
			loaded_count += 1

	print(
		"VIRTUAL_MEETUP_CHECK loaded=%d failed=%d total=%d"
		% [loaded_count, failures.size(), paths.size()]
	)
	for failed_path in failures:
		push_error("VIRTUAL_MEETUP_CHECK could not load %s" % failed_path)
	quit(0 if failures.is_empty() else 1)


func _collect_paths(root: String, paths: PackedStringArray) -> void:
	if not DirAccess.dir_exists_absolute(root):
		push_error("VIRTUAL_MEETUP_CHECK root is missing: %s" % root)
		return
	for file_name in DirAccess.get_files_at(root):
		var extension := file_name.get_extension().to_lower()
		if extension in EXTENSIONS:
			paths.append(root.path_join(file_name))
	for directory_name in DirAccess.get_directories_at(root):
		var child := root.path_join(directory_name)
		if child.contains("/drafts/"):
			continue
		_collect_paths(child, paths)
