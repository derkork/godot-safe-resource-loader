## This parser takes tokens from the resource lexer and returns a list of tags inside the resource file.
## It skips over stuff that isn't relevant for the use case of this addon, so you cannot get the 
## properties and their assigned values.

const Lexer = preload("resource_lexer.gd")

var _encountered_error: bool = false
## Whether the parser encountered an error durign parsing.
var encountered_error: bool:
	get: return _encountered_error

func parse(tokens: Array[Lexer.Token]) -> Array[Tag]:
	# strip any whitespace, newlines and comments
	var stripped_tokens: Array[Lexer.Token] = []
	for token in tokens:
		match token.type:
			Lexer.TokenType.WHITESPACE:
				continue
			Lexer.TokenType.NEWLINE:
				continue
			Lexer.TokenType.COMMENT:
				continue
			_:
				stripped_tokens.append(token)

	var context: MatchContext = MatchContext.new(stripped_tokens)
	var result: Array[Tag] = []
	
	while true:
		if context.is_end_of_file():
			break
		result.append(_tag(context))
		if _encountered_error:
			return []
	
	return result
	
func _tag(context:MatchContext) -> Tag:
	if not _sequence([_open_bracket(), _other("name")]).match_item(context):
		_report_unexpected_token(context)
		return null
	
	var tag: Tag = Tag.new()
	tag.name = context.retrieve("name")
	tag.line = context.retrieve_line("name")
	
	# now the attributes
	while _cache("attribute", func(): return _sequence( [_other("name"), _assign(), _value("value")])).match_item(context):
		var attribute: Attribute = Attribute.new()
		attribute.name = context.retrieve("name")
		attribute.value = context.retrieve("value")
		tag.attributes.append(attribute)
		
	# closing bracket
	if not _close_bracket().match_item(context):
		_report_unexpected_token(context)
		return null
		
	# finally any amount of key_value pairs, if they exist
	_cache("key_value_pairs", func(): return _repeat(_sequence([_other(), _assign(), _value()]))).match_item(context)
		
	return tag

#-- Non-terminal symbols
func _dictionary_declaration() -> MatchItem:
	# e.g.  Dictionary[String, int]({ "foo": 17, "bar": 5 })
	return _cache("dictionary_declaration", func(): return _sequence([
		_other_with_value("Dictionary"),
		_optional( # type declaration, which is optional
			_sequence([_open_bracket(), _type(), _comma(), _type(), _close_bracket()])
		),
		_open_paren(),
		_optional(_dictionary_literal()),
		_close_paren()
	]))
	
func _dictionary_literal() -> MatchItem:	
	# e.g.  { "foo": 17, "bar": 5 }, though keys can be any value
	var _key_value_pair := _sequence([ _value(), _colon(), _value() ])

	return _cache("dictionary_literal", func(): return _sequence([
		_open_curly(),
		_optional(_sequence( [_key_value_pair, _optional(_repeat(_sequence([_comma(), _key_value_pair])))])),
		_close_curly()
	]))

func _array_declaration() -> MatchItem:
	# e.g.  Array[int]([ 1, 2, 3 ])
	return _cache("array_declaration", func(): return _sequence([
		_other_with_value("Array"),
		_optional( # type declaration, which is optional
			_sequence([_open_bracket(), _type(), _close_bracket()]).named("type_declaration")
		),
		_open_paren(),
		_optional(_array_literal()),
		_close_paren()
	]))

func _array_literal() -> MatchItem:
	# e.g.  [ 1, 2, 3 ]
	return _cache("array_literal", func(): return  _sequence([
		_open_bracket(),
		_optional(_comma_separated_values()),
		_close_bracket()
	]))

func _comma_separated_values() -> MatchItem:
	# e.g.  1, 2, 3
	return _cache("csv", func(): return _sequence([ _value(), _optional(_repeat(_sequence([_comma(), _value()])))]))

	
func _invocation() -> MatchItem:
	# e.g. ExtResource("1_eau8o")
	return _cache("invocation", func(): return _sequence([
		_other(),
		_open_paren(),
		_optional(_comma_separated_values()),
		_close_paren()
	]))

func _value(target: String = "") -> MatchItem:
	# any valid value, including strings, numbers, identifiers, etc.
	return _cache("value::" + target, func(): return _one_of([
		_dictionary_declaration(),
		_dictionary_literal(),
		_array_declaration(),
		_array_literal(),
		_invocation(),
		_string(),
		_string_name(),
		_other(), 
	], target)
	)
	
# This is a type declaration in a dictionary or array.	
func _type() -> MatchItem:
	return _cache("type", func(): return _one_of([
		# complex things go first
		_invocation(), # reference to a custom script, usually an ExtResource invocation
		_other()  # simple identifier like, int, string, etc..
	]))
		

func _sequence(items: Array[MatchItem], target:String = "") -> MatchItem: return MatchItemSequence.new(items, target)
func _one_of(items: Array[MatchItem], target:String = "") -> MatchItem: return MatchItemOneOf.new(items, target)
func _optional(item: MatchItem, target:String = "") -> MatchItem: return MatchItemOptional.new(item, target)
func _repeat(item: MatchItem, target:String = "") -> MatchItem: return MatchItemRepeat.new(item, target)

#-- Terminal symbols
func _open_bracket() -> MatchItem: return _cache("open_bracket", func(): return MatchItemToken.new(Lexer.TokenType.OPEN_BRACKET))
func _close_bracket() -> MatchItem: return _cache("close_bracket", func(): return MatchItemToken.new(Lexer.TokenType.CLOSE_BRACKET))
func _open_curly() -> MatchItem: return _cache("open_curly", func(): return MatchItemToken.new(Lexer.TokenType.OPEN_CURLY))
func _close_curly() -> MatchItem: return _cache("close_curly", func(): return MatchItemToken.new(Lexer.TokenType.CLOSE_CURLY))
func _open_paren() -> MatchItem: return _cache("open_paren", func(): return MatchItemToken.new(Lexer.TokenType.OPEN_PAREN))
func _close_paren() -> MatchItem: return _cache("close_paren", func(): return MatchItemToken.new(Lexer.TokenType.CLOSE_PAREN))
func _colon() -> MatchItem: return _cache("colon", func(): return MatchItemToken.new(Lexer.TokenType.COLON))
func _assign() -> MatchItem: return _cache("assign", func(): return MatchItemToken.new(Lexer.TokenType.ASSIGN))
func _comma() -> MatchItem: return _cache("comma", func(): return MatchItemToken.new(Lexer.TokenType.COMMA))
func _other(target:String = "") -> MatchItem: return _cache("other::" + target, func(): return MatchItemToken.new(Lexer.TokenType.OTHER, target))
func _other_with_value(value:String, target:String = "") -> MatchItem: return _cache("other::" + target + "::" + value, func(): return MatchItemToken.new(Lexer.TokenType.OTHER, target).with_value(value))

func _string(target:String = "") -> MatchItem: return _cache("string::" + target, func(): return MatchItemToken.new(Lexer.TokenType.STRING, target))
func _string_name(target:String = "") -> MatchItem: return _cache("string_name::" + target, func(): return MatchItemToken.new(Lexer.TokenType.STRING_NAME, target))

# We use an item cache to avoid creating the same MatchItem multiple times and to avoid
# having infinite recursion when creating the MatchItem.
var _item_cache: Dictionary = {}
func _cache(key: StringName, callable:Callable) -> Variant:
	if not _item_cache.has(key):
		# put in a temporary value to avoid infinite recursion
		var pointer: MatchItemPointer = MatchItemPointer.new().named(key)
		_item_cache[key] = pointer
		
		# construct the item, this may result in a recursive call
		var item: MatchItem = callable.call()
		
		# inject the item into the pointer
		if pointer.item == null:
			pointer.item = item
		
	return _item_cache[key]

#-- Helper functions	
	
func _report_unexpected_token(context:MatchContext) -> void:
	_encountered_error = true
	if context.is_end_of_file():
		push_error("Unexpected end of file")
		return

	var token: Lexer.Token = context.next_token()
	push_error("Unexpected token '%s' at line %d" % [token.value, token.line])
	
	
class MatchItem:
	var _target: String = ""
	var name: String = ""
	
	func named(name:String) -> MatchItem:
		# Set the name of the item, used for debugging
		self.name = name
		return self
	
	func _init(target:String = ""):
		# Constructor for MatchItem
		# target is the string to match against
		_target = target
	
	func match_item(context:MatchContext) -> bool:
		var start_offset:int = context.offset
		var result: bool = _match(context)
		if result and not _target.is_empty():
			context.store(_target, start_offset)

# enable for debugging		
#		if result and name != "":
#			print("MATCH[%s]: %s" %  [name, context.get_text(start_offset)])
			

		return result
	
	func _match(context:MatchContext) -> bool:
		return false

class MatchItemPointer:
	extends MatchItem

	var item:MatchItem = null
	
	func _match(context:MatchContext) -> bool:
		if item == null:
			push_error("Probable bug, pointer should not point to null item.")
			return false
		return item.match_item(context)


class MatchItemSequence:
	extends MatchItem
	
	var _sequence: Array[MatchItem] = []

	func _init(sequence: Array[MatchItem], target:String = "") -> void:
		super(target)
		_sequence = sequence
	
	func _match(context:MatchContext) -> bool:
		context.mark()
		for item in _sequence:
			if not item.match_item(context):
				context.reset()
				return false
		context.keep()
		return true
		
class MatchItemRepeat:
	extends MatchItem
	var _item: MatchItem = null

	func _init(item: MatchItem, target:String = "") -> void:
		super(target)
		_item = item
	
	func _match(context:MatchContext) -> bool:
		var matched: int = 0
		while true:
			context.mark()
			if not _item.match_item(context):
				context.reset()
				break
			matched += 1
			context.keep()
	
		return matched > 0		

class MatchItemOneOf:
	extends MatchItem	
	var _items: Array[MatchItem] = []

	func _init(items: Array[MatchItem], target:String = "") -> void:
		super(target)
		_items = items
	
	func _match(context:MatchContext) -> bool:
		context.mark()
		for item in _items:
			if item.match_item(context):
				context.keep()
				return true
		context.reset()
		return false
		
class MatchItemOptional:
	extends MatchItem	
	var _item: MatchItem = null

	func _init(item: MatchItem, target:String = "") -> void:
		super(target)
		_item = item
	
	func _match(context:MatchContext) -> bool:
		context.mark()
		if _item.match_item(context):
			return true
		context.reset()
		return true # optional, so always return true
	
class MatchItemToken:
	extends MatchItem	
	var _token: Lexer.TokenType = -1
	var _must_have_value: bool = false
	var _expected_value: String = ""

	func _init(token: Lexer.TokenType, target:String = "") -> void:
		super(target)
		_token = token
		
	func with_value(expected_value:String) -> MatchItemToken:
		_expected_value = expected_value
		_must_have_value = true
		return self
	
	func _match(context:MatchContext) -> bool:
		context.mark()
		var token: Lexer.Token = context.next_token()
		if token == null:
			context.reset()
			return false
		if token.type != _token:
			context.reset()
			return false
		if _must_have_value and token.value != _expected_value:
			context.reset()
			return false
		return true
		
class MatchContext:
	var _tokens: Array[Lexer.Token] = []
	var _offset: int = -1
	var offset: int:
		get: return _offset

	var _count: int = 0
	var _marked_offsets: Array[int] = []
	var _stored:Dictionary = {}
	var _stored_line:Dictionary = {}
	
	func _init(tokens: Array[Lexer.Token]):	
		_tokens = tokens
		_count = tokens.size()
	
	func get_text(from_offset:int) -> String:
		var result: String = ""
		for i in range(from_offset, _offset):
			result += _tokens[i+1].value
		return result
	
	func store(target:String, from_offset:int):
		_stored[target] = get_text(from_offset)
		_stored_line[target] = _tokens[from_offset+1].line 
	
	func retrieve(target:String) -> String:
		if _stored.has(target):
			return _stored[target]
		return ""
		
	func retrieve_line(target:String) -> int:
		if _stored_line.has(target):
			return _stored_line[target]
		return -1

	func mark() -> void:
		_marked_offsets.append(_offset)	
	
	func reset() -> void:
		_offset = _marked_offsets.pop_back()
	
	func keep() -> void:
		_marked_offsets.pop_back()
	
	func next_token() -> Lexer.Token:
		_offset += 1
		if _offset < _count:
			return _tokens[_offset]
		return null

	func is_end_of_file() -> bool:
		return _offset + 1 >= _count

	
class Tag:
	var name: String = ""
	var attributes: Array[Attribute] = []
	var line: int = 0


	func _to_string() -> String:
		var result: String = "[" + name 
		if attributes.size() > 0:
			result += " "
		for i in attributes.size():
			var attribute := attributes[i]
			result += attribute.to_string()
			if i + 1 < attributes.size():
				result += " "
		result +=  "]\n"
		return result


class Attribute:
	var name: String = ""
	var value: String = ""
	
	func _to_string():
		return name + "=" + value
