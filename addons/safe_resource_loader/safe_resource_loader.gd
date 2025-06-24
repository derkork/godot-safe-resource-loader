class_name SafeResourceLoader

const Lexer = preload("resource_lexer.gd")
const Parser = preload("resource_parser.gd")

## Verifies if a resource file is safe to load by checking for embedded GDScript
## resources or external resources with paths outside of res://
## Returns true if the resource is safe, false otherwise
static func _verify_resource_safety(path:String) -> bool:
	# We only really support .tres files, so refuse to load anything else.
	if not path.ends_with(".tres"):
		push_error("This resource loader only supports .tres files.")
		return false

	# Also refuse to load anything within res:// as it should be safe and also
	# will not be readable after export anyways.
	if path.begins_with("res://"):
		push_error("This resource loader is intended for loading resources from unsafe " + \
				"origins (e.g. saved games downloaded from the internet). Using it on safe resources " + \
				"inside res:// will just slow down loading for no benefit. In addition it will not work " + \
				"on exported games as resources are packed and no longer readable from the file system.")
		return false

	# Check if the file exists.
	if not FileAccess.file_exists(path):
		push_error("Cannot load resource '" + path + "' because it does not exist or is not accessible.")
		return false

	# Load it as text content, only. This will not execute any scripts.
	var file = FileAccess.open(path, FileAccess.READ)
	var file_as_text = file.get_as_text()
	file.close()

	# Step 1: convert text file into an array of tokens
	var lexer:Lexer = Lexer.new()
	var tokens:Array[Lexer.Token] = lexer.tokens(file_as_text)
	if lexer.encountered_error:
		push_error("Error during lexing. If you think this file should work, please report this as a bug and include a copy of %s so this can be fixed." % path)
		return false

	# Step 2: parse tokens into tags
	var parser:Parser = Parser.new()
	var tags:Array[Parser.Tag] = parser.parse(tokens)
	if parser.encountered_error:
		push_error("Error during parsing. If you think this file should work, please report this as a bug and include a copy of %s so this can be fixed." % path)
		return false

	for tag in tags:
		# find any resource which has a type of "GDScript"
		if tag.attributes.any(func(it): return it.name == "type" and it.value == "GDScript"):
			push_warning("Resource '%s' contains inline GDScript in or around line %s." % [path, tag.line])
			return false

		# find any ext_resource which has a path outside of res://
		if tag.name != "ext_resource":
			continue

		for attribute in tag.attributes:
			if attribute.name == "path" and not attribute.value.begins_with("res://"):
				push_warning(("Resource '%s'\ncontains an ext_resource with a path " + \
					"outside 'res://' ('%s') in or around line %s.") % [path, attribute.value, tag.line ])
				return false

	return true

## Safely loads resource files (.tres) by scanning them for any
## embedded GDScript resources. If such resources are found, the
## loading will be aborted so embedded scripts cannote be executed.
## If loading fails for any reason, an error message will be printed
## and this function returns null.
static func load(path:String, type_hint:String = "", \
		cache_mode:ResourceLoader.CacheMode = ResourceLoader.CacheMode.CACHE_MODE_REUSE) -> Resource:

	if not _verify_resource_safety(path):
		return null

	# otherwise use the normal resource loader to load it.
	return ResourceLoader.load(path, type_hint, cache_mode)

## Safely initiates a threaded resource load by first verifying the resource safety.
## If the resource is not safe to load, returns ERR_INVALID_DATA.
## Otherwise, delegates to ResourceLoader.load_threaded_request.
static func load_threaded_request(path:String, type_hint:String = "", \
		use_sub_threads:bool = false, cache_mode:ResourceLoader.CacheMode = ResourceLoader.CacheMode.CACHE_MODE_REUSE) -> Error:

	if not _verify_resource_safety(path):
		return ERR_INVALID_DATA

	# Delegate to ResourceLoader if the resource is safe
	return ResourceLoader.load_threaded_request(path, type_hint, use_sub_threads, cache_mode)

## Gets the status of a threaded resource load started with load_threaded_request.
## Delegates to ResourceLoader.load_threaded_get_status.
static func load_threaded_get_status(path:String, progress:Array = []) -> ResourceLoader.ThreadLoadStatus:
	return ResourceLoader.load_threaded_get_status(path, progress)

## Gets the resource from a threaded resource load started with load_threaded_request.
## Delegates to ResourceLoader.load_threaded_get.
static func load_threaded_get(path:String) -> Resource:
	return ResourceLoader.load_threaded_get(path)
