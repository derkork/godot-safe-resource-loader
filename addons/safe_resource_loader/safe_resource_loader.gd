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
	
	# strip out any comments to make detection easier
	file_as_text = _strip_comments(file_as_text)

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
	# Another wrinkle is that Godot seems to happily load [ext_resource] declarations which
	# have multiple path=".." attributes, in which case it last one wins. This means that we
	# have to find any occurrence of path=".." which is not pointing towards res://

	var extResourceRegex:RegEx = RegEx.new()
	
	# We use this regex to find such ext_resource references. Since Godot allows whitespace
	# everwhere inside we have liberal sprinkling of \\s*. So this will will search for a
	# ext_resource which has any path=".." in it where the path doesn't start with res://
	extResourceRegex.compile("\\[\\s*ext_resource\\s+(\\s|.)*?path\\s*=\\s*(?!\"res:\\/\\/)(\\s|.)*?\\]")
	var matches:Array = extResourceRegex.search_all(file_as_text)
	
	# if we get matches print them out as warnings, then return null
	for match in matches:
		var entry = match.get_string()
		push_warning("Resource '" + path + "' contains an ext_resource with a path\n outside 'res://' (near: '" + entry + "'), will not load it.")
	
	if matches.size() > 0:
		return null

	# otherwise use the normal resource loader to load it.
	return ResourceLoader.load(path, type_hint, cache_mode)
	
## The resource format supports single-line comments, starting with ";"
## and ending with a newline. We strip them out here to avoid having to factor
## them into our detection logic. This is approaching a parser, albeit 
## a very simple one.
static func _strip_comments(text:String) -> String:

	# We have comments and we have strings. We don't want to find 
	# comment-like things inside strings, but at the same time we cannot
	# just ignore everything between quotes, because these quotes might
	# be inside a comment. So we will need an actual parser for this.
	# We go over the text character by character, and keep track of whether
	# we are inside a comment or a string. If we are inside a comment, we
	# ignore everything until the end of the line. If we are inside a string,
	# we don't look for comments.
	
	# The result string. We append to it when we have a known good set of 
	# characters.
	var result:String = ""
	# The index of last character we added to the result string.
	var write_offset:int = 0
	
	var in_comment:bool = false
	var in_string:bool = false
	
	for i in text.length():
		var char = text.unicode_at(i)
		# if we are in a string, we ignore everything until the end of the string.
		if in_string:
			if char == 34:  # 34 is unicode for double quote
				# check if the preceding character is a backslash, if so, we are not done with the string yet
				if i > 0 and text.unicode_at(i - 1) == 92:  # 92 is unicode for backslash
					continue
				in_string = false
			continue
		
		# if we are in a comment, we ignore everything until the end of the line.
		if in_comment:
			if char == 10:  # 10 is unicode for newline
				in_comment = false
				result += "\n"
				write_offset = i + 1
			continue
		
		if char == 59:  # 59 is unicode for semicolon
			# we are now starting a comment
			in_comment = true
			if i > write_offset:
				# we have seen some text before the comment, so we can write it to the result string
				result += text.substr(write_offset, i - write_offset)
				write_offset = i	
	
		if char == 34:  # 34 is unicode for double quote
			# we are now starting a string
			in_string = true
			# because we don't want to strip strings, we don't write anything just yet
	
	# if we are still in comment right now, we can ignore the rest
	if in_comment:
		return result
	
	# technically we can still be in string right now and that would make the whole thing
	# an invalid resource file, but that is something we hand over to the real resource loader
	# so we just write the rest of the string to the result string
	if write_offset < text.length():
		result += text.substr(write_offset, text.length() - write_offset)
		
	return result
	
