class_name InviteCode
extends RefCounted

const TOKEN_LENGTH := 8
const ALPHABET := "ABCDEFGHJKMNPQRSTVWXYZ23456789"
const ROOM_PREFIX := "vm1-"
const SUPPORTED_REGIONS := [&"us", &"usw", &"eu", &"asia", &"jp", &"au", &"cae", &"sa", &"in", &"kr", &"tr", &"za", &"mena"]


static func generate(region: StringName) -> String:
	var normalized_region := normalize_region(str(region))
	if normalized_region.is_empty():
		normalized_region = "us"
	var bytes := Crypto.new().generate_random_bytes(TOKEN_LENGTH)
	var token := ""
	for index in TOKEN_LENGTH:
		var byte_value := int(bytes[index]) if index < bytes.size() else randi()
		token += ALPHABET[byte_value % ALPHABET.length()]
	return "%s-%s" % [normalized_region.to_upper(), token]


static func parse(value: String) -> Dictionary:
	var normalized := value.strip_edges().to_upper().replace(" ", "")
	var separator := normalized.find("-")
	if separator <= 0:
		return {}
	var region := normalize_region(normalized.left(separator))
	var token := normalized.substr(separator + 1).replace("-", "")
	if region.is_empty() or token.length() != TOKEN_LENGTH:
		return {}
	for character in token:
		if ALPHABET.find(character) < 0:
			return {}
	return {
		"region": region,
		"token": token,
		"display": "%s-%s" % [region.to_upper(), token],
		"room_name": ROOM_PREFIX + token.to_lower(),
	}


static func normalize_region(value: String) -> String:
	var normalized := StringName(value.strip_edges().to_lower())
	return str(normalized) if SUPPORTED_REGIONS.has(normalized) else ""
