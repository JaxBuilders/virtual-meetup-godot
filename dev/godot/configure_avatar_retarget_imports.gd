extends SceneTree

const QUATERNIUS_SCENE := "res://assets/animations/quaternius_ual_standard/UAL1_Standard.glb"
const QUATERNIUS_MAP := "res://resources/avatars/quaternius_ual_standard_bone_map.tres"
const MAKEHUMAN_SCENE := "res://assets/avatars/makehuman_baseline.glb"
const MAKEHUMAN_MAP := "res://resources/avatars/makehuman_game_engine_bone_map.tres"
const WARDROBE_SCENE := "res://assets/avatars/makehuman_wardrobe_proof.glb"
const WARDROBE_MAP := "res://resources/avatars/makehuman_raw_game_engine_bone_map.tres"

const FINGER_BONES := {
	"LeftThumbMetacarpal": "thumb_01_l",
	"LeftThumbProximal": "thumb_02_l",
	"LeftThumbDistal": "thumb_03_l",
	"LeftIndexProximal": "index_01_l",
	"LeftIndexIntermediate": "index_02_l",
	"LeftIndexDistal": "index_03_l",
	"LeftMiddleProximal": "middle_01_l",
	"LeftMiddleIntermediate": "middle_02_l",
	"LeftMiddleDistal": "middle_03_l",
	"LeftRingProximal": "ring_01_l",
	"LeftRingIntermediate": "ring_02_l",
	"LeftRingDistal": "ring_03_l",
	"LeftLittleProximal": "pinky_01_l",
	"LeftLittleIntermediate": "pinky_02_l",
	"LeftLittleDistal": "pinky_03_l",
	"RightThumbMetacarpal": "thumb_01_r",
	"RightThumbProximal": "thumb_02_r",
	"RightThumbDistal": "thumb_03_r",
	"RightIndexProximal": "index_01_r",
	"RightIndexIntermediate": "index_02_r",
	"RightIndexDistal": "index_03_r",
	"RightMiddleProximal": "middle_01_r",
	"RightMiddleIntermediate": "middle_02_r",
	"RightMiddleDistal": "middle_03_r",
	"RightRingProximal": "ring_01_r",
	"RightRingIntermediate": "ring_02_r",
	"RightRingDistal": "ring_03_r",
	"RightLittleProximal": "pinky_01_r",
	"RightLittleIntermediate": "pinky_02_r",
	"RightLittleDistal": "pinky_03_r",
}

const QUATERNIUS_BONES := {
	"Root": "root",
	"Hips": "pelvis",
	"Spine": "spine_01",
	"Chest": "spine_02",
	"UpperChest": "spine_03",
	"Neck": "neck_01",
	"Head": "Head",
	"LeftShoulder": "clavicle_l",
	"LeftUpperArm": "upperarm_l",
	"LeftLowerArm": "lowerarm_l",
	"LeftHand": "hand_l",
	"RightShoulder": "clavicle_r",
	"RightUpperArm": "upperarm_r",
	"RightLowerArm": "lowerarm_r",
	"RightHand": "hand_r",
	"LeftUpperLeg": "thigh_l",
	"LeftLowerLeg": "calf_l",
	"LeftFoot": "foot_l",
	"LeftToes": "ball_l",
	"RightUpperLeg": "thigh_r",
	"RightLowerLeg": "calf_r",
	"RightFoot": "foot_r",
	"RightToes": "ball_r",
}

const MAKEHUMAN_BONES := {
	"Root": "Root",
	"Hips": "pelvis",
	"Spine": "spine_01",
	"Chest": "spine_02",
	"UpperChest": "spine_03",
	"Neck": "neck_01",
	"Head": "head",
	"LeftShoulder": "clavicle_l",
	"LeftUpperArm": "upperarm_l",
	"LeftLowerArm": "lowerarm_l",
	"LeftHand": "hand_l",
	"RightShoulder": "clavicle_r",
	"RightUpperArm": "upperarm_r",
	"RightLowerArm": "lowerarm_r",
	"RightHand": "hand_r",
	"LeftUpperLeg": "thigh_l",
	"LeftLowerLeg": "calf_l",
	"LeftFoot": "foot_l",
	"LeftToes": "ball_l",
	"RightUpperLeg": "thigh_r",
	"RightLowerLeg": "calf_r",
	"RightFoot": "foot_r",
	"RightToes": "ball_r",
}

const WARDROBE_BONES := {
	"Root": "Root",
	"Hips": "pelvis",
	"Spine": "spine_01",
	"Chest": "spine_02",
	"UpperChest": "spine_03",
	"Neck": "neck_01",
	"Head": "head",
	"LeftShoulder": "clavicle_l",
	"LeftUpperArm": "upperarm_l",
	"LeftLowerArm": "lowerarm_l",
	"LeftHand": "hand_l",
	"RightShoulder": "clavicle_r",
	"RightUpperArm": "upperarm_r",
	"RightLowerArm": "lowerarm_r",
	"RightHand": "hand_r",
	"LeftUpperLeg": "thigh_l",
	"LeftLowerLeg": "calf_l",
	"LeftFoot": "foot_l",
	"LeftToes": "ball_l",
	"RightUpperLeg": "thigh_r",
	"RightLowerLeg": "calf_r",
	"RightFoot": "foot_r",
	"RightToes": "ball_r",
}


func _initialize() -> void:
	var failed := false
	failed = not _configure(QUATERNIUS_SCENE, QUATERNIUS_MAP, QUATERNIUS_BONES, false, false) or failed
	failed = not _configure(MAKEHUMAN_SCENE, MAKEHUMAN_MAP, MAKEHUMAN_BONES, false, true) or failed
	failed = not _configure(WARDROBE_SCENE, WARDROBE_MAP, WARDROBE_BONES, true, true) or failed
	if failed:
		push_error("Avatar retarget import configuration failed.")
		quit(1)
		return
	print("VIRTUAL_MEETUP_RETARGET_IMPORTS configured=3")
	quit()


func _configure(
	scene_path: String,
	map_path: String,
	mappings: Dictionary,
	embed_images: bool,
	fix_silhouette: bool
) -> bool:
	var complete_mappings := mappings.duplicate()
	complete_mappings.merge(FINGER_BONES)
	var map := BoneMap.new()
	map.profile = SkeletonProfileHumanoid.new()
	for profile_bone: String in complete_mappings:
		map.set_skeleton_bone_name(profile_bone, complete_mappings[profile_bone])
	if ResourceSaver.save(map, map_path) != OK:
		push_error("Could not save %s" % map_path)
		return false
	_normalize_crlf(map_path)
	# This is the source glTF path, before the importer renames the node to
	# GeneralSkeleton. Keeping it explicit makes this configurator idempotent.
	var skeleton_path := "PATH:Armature/Skeleton3D"
	var import_config := ConfigFile.new()
	var import_path := "%s.import" % scene_path
	if import_config.load(import_path) != OK:
		push_error("Could not load %s" % import_path)
		return false
	var subresources: Dictionary = import_config.get_value("params", "_subresources", {})
	var nodes: Dictionary = subresources.get("nodes", {})
	nodes[skeleton_path] = {
		"retarget/bone_map": map,
		"retarget/bone_renamer/rename_bones": true,
		"retarget/bone_renamer/unique_node/make_unique": true,
		"retarget/bone_renamer/unique_node/skeleton_name": "GeneralSkeleton",
		"retarget/remove_tracks/except_bone_transform": false,
		"retarget/remove_tracks/unimportant_positions": true,
		"retarget/remove_tracks/unmapped_bones": 1,
		"retarget/rest_fixer/apply_node_transforms": true,
		"retarget/rest_fixer/normalize_position_tracks": true,
		"retarget/rest_fixer/reset_all_bone_poses_after_import": true,
		"retarget/rest_fixer/retarget_method": 1,
		"retarget/rest_fixer/keep_global_rest_on_leftovers": true,
		# MPFB exports its game-engine rig in an A-pose. Godot's humanoid
		# animation-sharing contract is a T-pose, so MakeHuman targets need the
		# silhouette correction in addition to overwritten bone axes. The
		# Quaternius animation source is already a T-pose.
		"retarget/rest_fixer/fix_silhouette/enable": fix_silhouette,
	}
	if scene_path == QUATERNIUS_SCENE:
		nodes["PATH:Armature/Skeleton3D/Mannequin"] = {"import/skip_import": true}
	subresources["nodes"] = nodes
	import_config.set_value("params", "_subresources", subresources)
	if embed_images:
		import_config.set_value("params", "gltf/embedded_image_handling", 2)
	if import_config.save(import_path) != OK:
		push_error("Could not update %s" % import_path)
		return false
	_normalize_crlf(import_path)
	print("Configured %s at %s" % [scene_path, skeleton_path])
	return true


func _normalize_crlf(path: String) -> void:
	var text := FileAccess.get_file_as_string(path).replace("\r\n", "\n").replace("\n", "\r\n")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not normalize line endings for %s" % path)
		return
	file.store_string(text)
