## StoryDataLoader.gd
## -------------------------------------------------------
## Loads story card data from JSON files.
## Each JSON file should be an array of card objects:
##   [ { "text": "Hello world", "image": "res://assets/story/img.png" }, ... ]
##
## "image" is optional. Cards without images show text only.
## -------------------------------------------------------
class_name StoryDataLoader

## Load a single story JSON file. Returns empty array on error.
static func load_story(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		push_warning("StoryDataLoader: file not found — %s" % path)
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("StoryDataLoader: cannot open — %s" % path)
		return []

	var raw: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(raw)
	if err != OK:
		push_warning("StoryDataLoader: parse error in %s — %s" % [path, json.get_error_message()])
		return []

	var data: Variant = json.data
	if data is not Array:
		push_warning("StoryDataLoader: root must be an array — %s" % path)
		return []

	var result: Array[Dictionary] = []
	for item: Variant in data:
		if item is Dictionary:
			result.append(item)
		else:
			push_warning("StoryDataLoader: skipping non-dict item in %s" % path)

	return result


## Convenience: load level intro/outro stories.
## Returns { "intro": [...], "outro": [...] }.
## If a file doesn't exist, its key will be an empty array.
static func load_level_stories(level_index: int) -> Dictionary:
	var base: String = "res://data/story/level%d" % level_index
	return {
		"intro": load_story(base + "_intro.json"),
		"outro": load_story(base + "_outro.json"),
	}


## Convenience: load the game intro story.
static func load_intro() -> Array[Dictionary]:
	return load_story("res://data/story/intro.json")
