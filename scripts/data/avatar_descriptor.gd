class_name AvatarDescriptor
extends Resource

const BODY_IDS := [&"body_compact", &"body_tall"]
const SKIN_IDS := [&"skin_amber", &"skin_umber", &"skin_rose", &"skin_sand", &"skin_brown", &"skin_deep"]
const HAIR_IDS := [&"hair_crop", &"hair_cap", &"hair_bun"]
const OUTFIT_IDS := [&"outfit_teal", &"outfit_orange", &"outfit_violet"]
const ACCESSORY_IDS := [&"none", &"glasses", &"badge"]

@export var body_id: StringName = BODY_IDS[0]
@export var skin_id: StringName = SKIN_IDS[0]
@export var hair_id: StringName = HAIR_IDS[0]
@export var outfit_id: StringName = OUTFIT_IDS[0]
@export var accessory_id: StringName = ACCESSORY_IDS[0]


func sanitize() -> void:
	body_id = _allow(body_id, BODY_IDS, BODY_IDS[0])
	skin_id = _allow(skin_id, SKIN_IDS, SKIN_IDS[0])
	hair_id = _allow(hair_id, HAIR_IDS, HAIR_IDS[0])
	outfit_id = _allow(outfit_id, OUTFIT_IDS, OUTFIT_IDS[0])
	accessory_id = _allow(accessory_id, ACCESSORY_IDS, ACCESSORY_IDS[0])


func duplicate_descriptor() -> AvatarDescriptor:
	var copy := AvatarDescriptor.new()
	copy.body_id = body_id
	copy.skin_id = skin_id
	copy.hair_id = hair_id
	copy.outfit_id = outfit_id
	copy.accessory_id = accessory_id
	return copy


func to_dictionary() -> Dictionary:
	return {
		"body": str(body_id),
		"skin": str(skin_id),
		"hair": str(hair_id),
		"outfit": str(outfit_id),
		"accessory": str(accessory_id),
	}


static func from_dictionary(value: Dictionary) -> AvatarDescriptor:
	var descriptor := AvatarDescriptor.new()
	descriptor.body_id = StringName(str(value.get("body", descriptor.body_id)))
	descriptor.skin_id = StringName(str(value.get("skin", descriptor.skin_id)))
	descriptor.hair_id = StringName(str(value.get("hair", descriptor.hair_id)))
	descriptor.outfit_id = StringName(str(value.get("outfit", descriptor.outfit_id)))
	descriptor.accessory_id = StringName(str(value.get("accessory", descriptor.accessory_id)))
	descriptor.sanitize()
	return descriptor


static func _allow(value: StringName, allowed: Array, fallback: StringName) -> StringName:
	return value if allowed.has(value) else fallback
