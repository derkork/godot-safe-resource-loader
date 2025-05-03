extends GdUnitTestSuite

const Lexer = preload("res://addons/safe_resource_loader/resource_lexer.gd")
const Parser = preload("res://addons/safe_resource_loader/resource_parser.gd")

func test_parser():
	var sample_files:Array[String] = [
		"res://tests/data/contains_duplicate_path_attributes.tres", 
		"res://tests/data/contains_extra_line_breaks.tres", 
		"res://tests/data/contains_inline_scripts.tres", 
		"res://tests/data/contains_legacy_string_names.tres", 
		"res://tests/data/contains_node_paths.tres", 
		"res://tests/data/contains_path_outside_res.tres", 
		"res://tests/data/contains_string_names.tres", 
		"res://tests/data/obscures_attributes_with_comments.tres", 
		"res://tests/data/safe.tres", 
		"res://tests/data/safe_4.4.tres"
	]
	for file in sample_files:
		_assert_can_parse(file)
	
	
	
func _assert_can_parse(file:String):
	var input = FileAccess.get_file_as_string(file)
	var lexer := Lexer.new()
	var result = lexer.tokens(input)
	for token in result:
		print(token)
		
	assert_bool(lexer.encountered_error).is_false()

	var parser := Parser.new()
	var parsed := parser.parse(result)
	
	assert_bool(parser.encountered_error).is_false()
	
	for tag in parsed:
		print(tag)
		
	assert_array(parsed).is_not_empty()
	
