extends GdUnitTestSuite

const Lexer = preload("res://addons/safe_resource_loader/resource_lexer.gd")
const Parser = preload("res://addons/safe_resource_loader/resource_parser.gd")

func test_simple_parsing():
	var input = FileAccess.get_file_as_string("res://tests/data/safe.tres")
	var lexer := Lexer.new()
	var result = lexer.tokens(input)
	print(result)

	var parser := Parser.new()
	var parsed := parser.parse(result)
	
	for tag in parsed:
		print(tag)
	
