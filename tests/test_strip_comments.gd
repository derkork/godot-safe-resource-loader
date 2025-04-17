extends GdUnitTestSuite

func test_comments_are_stripped():
	var input = "lorem ;ipsum\ndolor sit amet"
	var output = SafeResourceLoader._strip_comments(input)
	assert_str(output).is_equal("lorem \ndolor sit amet")


func test_comments_inside_of_strings_are_ignored():
	var input = "lorem ;ipsum\nipsum dolor \"sit ;amet\""
	var output = SafeResourceLoader._strip_comments(input)
	assert_str(output).is_equal("lorem \nipsum dolor \"sit ;amet\"")


func test_quotes_inside_of_strings_are_handled():
	var input = "lorem ipsum dolor \"sit \\\";amet\""
	var output = SafeResourceLoader._strip_comments(input)
	assert_str(output).is_equal(input)

	
func test_quoted_string_inside_of_comment_is_still_stripped():
	var input = "lorem ipsum dolor ;\"sit amet\""
	var output = SafeResourceLoader._strip_comments(input)
	assert_str(output).is_equal("lorem ipsum dolor ")

	
func test_trailing_string_is_ignored():
	var input = "lorem ipsum dolor \"sit amet"
	var output = SafeResourceLoader._strip_comments(input)
	assert_str(output).is_equal(input)
