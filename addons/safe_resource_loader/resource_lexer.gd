## This is a lexer for reading godot resource files. It returns a list of tokens.
## This can then be used to parse the resource file and check for any unsafe content.
## Note that this is a simplified version which is sufficient to check the things
## we need for our plugin (mainly tags and their attributes) but simplifies things
## like expressions into an "OTHER" token. As such it's not a general purpose 
## resource file lexer.

# Token types
enum TokenType {
	COMMENT,
	STRING,
	STRING_NAME,
	WHITESPACE,
	NEWLINE, # unicode 10, everything else is whitespace
	OPEN_CURLY,
	CLOSE_CURLY,
	OPEN_BRACKET,
	CLOSE_BRACKET,
	OPEN_PAREN,
	CLOSE_PAREN,
	COLON,
	ASSIGN,
	COMMA,
	OTHER # anything that is not the above. for our purposes we don't need more
}


var _text: String = ""
var _length: int = 0
var _offset: int = 0
var _tokens: Array[Token] = []
var _line:int = 1

var _encountered_error:bool = false
## Whether the lexer encountered an error durign lexing.
var encountered_error:bool:
	get: return _encountered_error

func tokens(text: String) -> Array[Token]:
	_text = text
	_length = text.length()
	_offset = 0
	_line = 1
	_encountered_error = false

	while _offset < _length:
		var token: Token = _next_token()
		if token:
			_tokens.append(token)
		else:
			push_error("Encountered unknown token at line %s (file offset %)" %  [_line, _offset])
			_encountered_error = true
			return []

	return _tokens

func _current_char() -> int:
	return _text.unicode_at(_offset)

func _next_token() -> Token:
	# calling _current_char is somewhat expensive, so we cache it
	var c: int = _current_char()

	# check for comments (starting with ; and ending with \n)
	if c == 59:  # 59 is unicode for semicolon
		return _read_comment()

	# check for newline
	if c == 10: # 10 is unicode for newline
		_line += 1
		_offset += 1
		return Token.new(TokenType.NEWLINE, "\\n", _offset - 1, _offset, _line - 1)

	# check for whitespace
	if _is_whitespace(c):
		return _read_whitespace()

	# check for strings (starting with " and ending with ")
	if c == 34:  # 34 is unicode for double quote
		return _read_string()

	# check for string names (starting with @ or & followed by " and ending with ")
	if c == 64 or c == 38:  # 64 is unicode for @, 38 is unicode for &
		# check if the next character is a double quote
		if _offset + 1 < _length and _text.unicode_at(_offset + 1) == 34:  # 34 is unicode for double quote
			_offset += 1  # skip the @ or &
			return _read_string_name()

	# check for curly braces	
	if c == 123:  # 123 is unicode for {
		_offset += 1
		return Token.new(TokenType.OPEN_CURLY, "{", _offset - 1, _offset, _line)
	
	if c == 125:  # 125 is unicode for }
		_offset += 1
		return Token.new(TokenType.CLOSE_CURLY, "}", _offset - 1, _offset, _line)

	# check for brackets
	if c == 91:  # 91 is unicode for [
		_offset += 1
		return Token.new(TokenType.OPEN_BRACKET, "[", _offset - 1, _offset, _line)

	if c == 93:  # 93 is unicode for ]
		_offset += 1
		return Token.new(TokenType.CLOSE_BRACKET, "]", _offset - 1, _offset, _line)

	# check for parentheses	
	if c == 40:  # 40 is unicode for (
		_offset += 1
		return Token.new(TokenType.OPEN_PAREN, "(", _offset - 1, _offset, _line)

	if c == 41:  # 41 is unicode for )
		_offset += 1
		return Token.new(TokenType.CLOSE_PAREN, ")", _offset - 1, _offset, _line)

	# check for colon
	if c == 58:  # 58 is unicode for :
		_offset += 1
		return Token.new(TokenType.COLON, ":", _offset - 1, _offset, _line)
	
	# check for assignment
	if c == 61:  # 61 is unicode for =
		_offset += 1
		return Token.new(TokenType.ASSIGN, "=", _offset - 1, _offset, _line)

	# check for comma
	if c == 44:  # 44 is unicode for ,
		_offset += 1
		return Token.new(TokenType.COMMA, ",", _offset - 1, _offset, _line)
	
	# anything else is an "other" token (doesn't match any of the above). 
	# however we don't want to return a token for every single character, so we
	# we collect all of the characters until we find one of the above tokens.
	var start: int = _offset
	while _offset < _length:
		c = _current_char()
		# if the character is any of the preceding stuff, we are done
		if c == 59 or _is_whitespace(c) or c == 10 or c == 34 or c == 91 or c == 93 or c == 40 or c == 41 or c == 58 or c == 61 or c == 44:
			break
		# special case for string names, we want to stop if we see a @ or & followed by a "
		if c == 64 or c == 38:
			if _offset + 1 < _length and _text.unicode_at(_offset + 1) == 34:  # 34 is unicode for double quote
				break
		_offset += 1
	
	var end: int = _offset
	var value: String = _text.substr(start, end - start)
	# if the value is empty, we don't want to return a token
	if value == "":
		# should never happen
		return null

	return Token.new(TokenType.OTHER, value, start, end, _line)




func _read_comment() -> Token:
	var start: int = _offset
	while _offset < _length and _current_char() != 10:  # 10 is unicode for newline
		_offset += 1
	
	var end: int = _offset - 1
	return Token.new(TokenType.COMMENT, _text.substr(start, end - start), start, end, _line)

func _is_whitespace(c: int) -> bool:
	return c == 32 or c == 9 or c == 13  # space, tab, carriage return

func _read_whitespace() -> Token:
	var start: int = _offset
	while _offset < _length and _is_whitespace(_current_char()):
		_offset += 1
	var end: int = _offset
	return Token.new(TokenType.WHITESPACE, _text.substr(start, end - start), start, end, _line)

func _read_string() -> Token:
	var start: int = _offset
	_offset += 1  # skip the opening quote
	while _offset < _length and _current_char() != 34:  # 34 is unicode for double quote
		if _current_char() == 92:  # 92 is unicode for backslash
			_offset += 1  # skip the backslash (and the next character)
		_offset += 1
	var end: int = _offset
	_offset += 1  # skip the closing quote
	return Token.new(TokenType.STRING, _text.substr(start+1, end - start -1), start, end, _line)


func _read_string_name() -> Token:
	var start: int = _offset
	_offset += 1  # skip the opening @ or &
	while _offset < _length and _current_char() != 34:  # 34 is unicode for double quote
		if _current_char() == 92:  # 92 is unicode for backslash
			_offset += 1  # skip the backslash (and the next character)
		_offset += 1
	var end: int = _offset
	_offset += 1  # skip the closing quote
	return Token.new(TokenType.STRING_NAME, _text.substr(start, end - start), start, end, _line)

class Token:
	var type: TokenType
	var type_as_string:String:
		get:
			match type:
				TokenType.COMMENT: return "COMMENT"
				TokenType.STRING: return "STRING"
				TokenType.STRING_NAME: return "STRING_NAME"
				TokenType.WHITESPACE: return "WHITESPACE"
				TokenType.NEWLINE: return "NEWLINE"
				TokenType.OPEN_CURLY: return "OPEN_CURLY"
				TokenType.CLOSE_CURLY: return "CLOSE_CURLY"
				TokenType.OPEN_BRACKET: return "OPEN_BRACKET"
				TokenType.CLOSE_BRACKET: return "CLOSE_BRACKET"
				TokenType.OPEN_PAREN: return "OPEN_PAREN"
				TokenType.CLOSE_PAREN: return "CLOSE_PAREN"
				TokenType.COLON: return "COLON"
				TokenType.ASSIGN: return "ASSIGN"
				TokenType.COMMA: return "COMMA"
				TokenType.OTHER: return "OTHER"
			return "UNKNOWN"
			
	var value: String
	var start: int
	var end: int
	var line: int

	func _init(type: TokenType, value: String, start: int, end: int, line:int):
		self.type = type
		self.value = value
		self.start = start
		self.end = end
		self.line = line

	

	func _to_string() -> String:
		return "%s: %s (%d, %d) @ %s" % [type_as_string, value, start, end, line]
		
