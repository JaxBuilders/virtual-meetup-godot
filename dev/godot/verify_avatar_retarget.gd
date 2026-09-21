extends SceneTree

const SOURCE_SCENE := preload("res://assets/animations/quaternius_ual_standard/UAL1_Standard.glb")
const TARGET_SCENE := preload("res://assets/avatars/makehuman_baseline.glb")
const WARDROBE_SCENE := preload("res://assets/avatars/makehuman_wardrobe_proof.glb")
const REQUIRED_ACTIONS := [
	&"Idle",
	&"Walk",
	&"Jog_Fwd",
	&"Jump_Start",
	&"Jump",
	&"Jump_Land",
	&"Sitting_Enter",
	&"Sitting_Idle",
	&"Dance",
]


func _initialize() -> void:
	var source := SOURCE_SCENE.instantiate()
	var target := TARGET_SCENE.instantiate()
	var wardrobe := WARDROBE_SCENE.instantiate()
	var source_skeleton := _find_skeleton(source)
	var target_skeleton := _find_skeleton(target)
	var source_player := _find_animation_player(source)
	var wardrobe_skeleton := _find_skeleton(wardrobe)
	if source_skeleton == null or target_skeleton == null or wardrobe_skeleton == null or source_player == null:
		push_error("Retarget source or target is missing its required nodes.")
		quit(1)
		return
	if source_skeleton.name != &"GeneralSkeleton" or target_skeleton.name != &"GeneralSkeleton" or wardrobe_skeleton.name != &"GeneralSkeleton":
		push_error("Retarget imports did not normalize both skeleton node names.")
		quit(1)
		return
	var source_bones := _bone_names(source_skeleton)
	var target_bones := _bone_names(target_skeleton)
	var wardrobe_bones := _bone_names(wardrobe_skeleton)
	var humanoid_profile := SkeletonProfileHumanoid.new()
	if not _has_anatomical_t_pose(source_skeleton):
		wardrobe.free()
		_fail(source, target, "The animation source arm mapping is not an anatomical T-pose.")
		return
	if not _has_anatomical_t_pose(target_skeleton):
		wardrobe.free()
		_fail(source, target, "The baseline arm mapping was not normalized from MPFB's A-pose.")
		return
	if not _has_anatomical_t_pose(wardrobe_skeleton):
		wardrobe.free()
		_fail(source, target, "The wardrobe arm mapping was not normalized from MPFB's A-pose.")
		return
	if not _arm_rests_match(target_skeleton, wardrobe_skeleton):
		wardrobe.free()
		_fail(source, target, "The bare and wardrobe MPFB proofs no longer share the same armature rest.")
		return
	for profile_index in humanoid_profile.get_bone_size():
		var required_bone := humanoid_profile.get_bone_name(profile_index)
		if required_bone in source_bones and required_bone not in target_bones:
			push_error("Source animation uses profile bone %s missing from target." % required_bone)
			quit(1)
			return
		if required_bone in source_bones and required_bone not in wardrobe_bones:
			push_error("Source animation uses profile bone %s missing from wardrobe target." % required_bone)
			quit(1)
			return
	var animations := source_player.get_animation_list()
	print("Quaternius actions: %s" % [animations])
	if not source.find_children("*", "MeshInstance3D", true, false).is_empty():
		_fail(source, target, "The runtime animation source should not import its reference mannequin mesh.")
		return
	if animations.size() != 43:
		_fail(source, target, "Expected 43 Quaternius actions, found %d." % animations.size())
		return
	for action: StringName in REQUIRED_ACTIONS:
		if action not in animations:
			_fail(source, target, "Missing required proof action %s." % action)
			return
	for loop_name: StringName in [&"Idle", &"Walk", &"Jog_Fwd", &"Sitting_Idle", &"Dance"]:
		if source_player.get_animation(loop_name).loop_mode == Animation.LOOP_NONE:
			_fail(source, target, "Expected %s to retain its loop metadata." % loop_name)
			return
	var test_action := source_player.get_animation(&"Walk")
	var compatible_tracks := 0
	for track_index in test_action.get_track_count():
		var track_path := str(test_action.track_get_path(track_index))
		if "GeneralSkeleton:" in track_path:
			compatible_tracks += 1
	if compatible_tracks < 20:
		push_error("Walk does not expose enough normalized humanoid tracks.")
		quit(1)
		return
	root.add_child(target)
	var target_player := AnimationPlayer.new()
	target.add_child(target_player)
	var proof_library := AnimationLibrary.new()
	proof_library.add_animation(&"Walk", test_action)
	target_player.add_animation_library(&"", proof_library)
	var upper_arm_index := target_skeleton.find_bone(&"LeftUpperArm")
	var before := target_skeleton.get_bone_pose_rotation(upper_arm_index)
	target_player.play(&"Walk")
	target_player.advance(test_action.length * 0.25)
	var after := target_skeleton.get_bone_pose_rotation(upper_arm_index)
	if before.angle_to(after) < 0.001:
		wardrobe.free()
		_fail(source, target, "The shared Walk action did not animate the MakeHuman target skeleton.")
		return
	root.add_child(wardrobe)
	var wardrobe_player := AnimationPlayer.new()
	wardrobe.add_child(wardrobe_player)
	wardrobe_player.add_animation_library(&"", proof_library)
	var wardrobe_arm_index := wardrobe_skeleton.find_bone(&"RightUpperArm")
	var wardrobe_before := wardrobe_skeleton.get_bone_pose_rotation(wardrobe_arm_index)
	wardrobe_player.play(&"Walk")
	wardrobe_player.advance(test_action.length * 0.25)
	var wardrobe_after := wardrobe_skeleton.get_bone_pose_rotation(wardrobe_arm_index)
	if wardrobe_before.angle_to(wardrobe_after) < 0.001:
		wardrobe.queue_free()
		_fail(source, target, "The shared Walk action did not animate the wardrobe target skeleton.")
		return
	print("VIRTUAL_MEETUP_RETARGET_CHECK actions=%d source_bones=%d target_bones=%d wardrobe_bones=%d walk_tracks=%d" % [
		animations.size(), source_bones.size(), target_bones.size(), wardrobe_bones.size(), compatible_tracks,
	])
	source.free()
	wardrobe.queue_free()
	target.queue_free()
	quit()


func _fail(source: Node, target: Node, message: String) -> void:
	push_error(message)
	source.free()
	target.free()
	quit(1)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _bone_names(skeleton: Skeleton3D) -> Array[StringName]:
	var names: Array[StringName] = []
	for bone_index in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(bone_index))
	return names


func _has_anatomical_t_pose(skeleton: Skeleton3D) -> bool:
	var left_upper := _rest_origin(skeleton, &"LeftUpperArm")
	var left_lower := _rest_origin(skeleton, &"LeftLowerArm")
	var left_hand := _rest_origin(skeleton, &"LeftHand")
	var right_upper := _rest_origin(skeleton, &"RightUpperArm")
	var right_lower := _rest_origin(skeleton, &"RightLowerArm")
	var right_hand := _rest_origin(skeleton, &"RightHand")
	if left_upper == Vector3.INF or right_upper == Vector3.INF:
		return false
	var extends_to_correct_sides := (
		left_upper.x > 0.0
		and left_upper.x < left_lower.x
		and left_lower.x < left_hand.x
		and right_upper.x < 0.0
		and right_upper.x > right_lower.x
		and right_lower.x > right_hand.x
	)
	var left_is_horizontal := absf(left_upper.y - left_lower.y) < 0.01 and absf(left_lower.y - left_hand.y) < 0.01
	var right_is_horizontal := absf(right_upper.y - right_lower.y) < 0.01 and absf(right_lower.y - right_hand.y) < 0.01
	return extends_to_correct_sides and left_is_horizontal and right_is_horizontal


func _arm_rests_match(first: Skeleton3D, second: Skeleton3D) -> bool:
	for bone_name: StringName in [&"LeftUpperArm", &"LeftLowerArm", &"LeftHand", &"RightUpperArm", &"RightLowerArm", &"RightHand"]:
		var first_index := first.find_bone(bone_name)
		var second_index := second.find_bone(bone_name)
		if first_index < 0 or second_index < 0:
			return false
		var first_rest := first.get_bone_global_rest(first_index)
		var second_rest := second.get_bone_global_rest(second_index)
		if not first_rest.is_equal_approx(second_rest):
			return false
	return true


func _rest_origin(skeleton: Skeleton3D, bone_name: StringName) -> Vector3:
	var bone_index := skeleton.find_bone(bone_name)
	if bone_index < 0:
		return Vector3.INF
	return skeleton.get_bone_global_rest(bone_index).origin
