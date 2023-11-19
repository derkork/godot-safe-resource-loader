class_name SafeResourceLoader

## Safely loads resource files (.tres) by scanning them for any
## embedded GDScript resources. If such resources are found, the
## loading will be aborted so embedded scripts cannote be executed.
## If loading fails for any reason, an error message will be printed
## and this function returns null.
static func load(path:String, type_hint:String = "", \
		cache_mode:ResourceLoader.CacheMode = ResourceLoader.CacheMode.CACHE_MODE_REUSE) -> Resource:
	
	# We only really support .tres files, so refuse to load anything else.
	if not path.ends_with(".tres"):
		push_error("This resource loader only supports .tres files.")
		return null	
	
	# Also refuse to load anything within res:// as it should be safe and also
	# will not be readable after export anyways.
	if path.begins_with("res://"):
		push_error("This resource loader is intended for loading resources from unsafe " + \
				"origins (e.g. saved games downloaded from the internet). Using it on safe resources " + \
				"inside res:// will just slow down loading for no benefit. In addition it will not work " + \
				"on exported games as resources are packed and no longer readable from the file system.")
		return null
		
	# Check if the file exists.
	if not FileAccess.file_exists(path):
		push_error("Cannot load resource '" + path + "' because it does not exist or is not accessible.")
		return null
	
	# Load it as text content, only. This will not execute any scripts.
	var file = FileAccess.open(path, FileAccess.READ)
	var file_as_text = file.get_as_text()
	file.close()

	# Use a regex to find any instance of an embedded GDScript resource.
	var regex:RegEx = RegEx.new()
	regex.compile("type\\s*=\\s*\"GDScript\"\\s*")	
	
	# If we found one, bail out.
	if regex.search(file_as_text) != null:
		push_warning("Resource '" + path + "' contains inline GDScripts, will not load it.")
		return null

	# Check all ext resources, and verify that all their paths start with res://
	# This is to prevent loading resources from outside the game directory.
	#
	# Format is: 
	# [ext_resource type="Script" path="res://safe_resource_loader_example/saved_game.gd" id="1_on72l"]
	# there can be arbitrary whitespace between [] or the key/value pairs. the order of the key/value pairs is arbitrary.
	# we want to match the path key, and then check that the value starts with res:// 
	# the type doesn't matter, as resources themselves could contain further resources, which in turn could contain
	# scripts, so we flat-out refuse to load ANY resource that isn't in res://

	var extResourceRegex:RegEx = RegEx.new()
	extResourceRegex.compile("\\[\\s*ext_resource\\s*.*?path\\s*=\\s*\"([^\"]*)\".*?\\]")
	var matches:Array = extResourceRegex.search_all(file_as_text)
	for match in matches:
		var resourcePath:String = match.get_string(1)
		if not resourcePath.begins_with("res://"):
			push_warning("Resource '" + path + "' contains an ext_resource with a path\n outside 'res://' (path is: '" + resourcePath + "'), will not load it.")
			return null

	# otherwise use the normal resource loader to load it.
	return ResourceLoader.load(path, type_hint, cache_mode)
	
