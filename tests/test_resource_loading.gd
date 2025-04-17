extends GdUnitTestSuite

func _resource_path(tres_file: String):
	return ProjectSettings.globalize_path("res://tests/data/%s" % tres_file)


func test_load_safe_resource_works():
	var result = SafeResourceLoader.load(_resource_path("safe.tres"))
	assert_that(result).is_not_null()


func test_load_resource_with_inline_script_is_blocked():
	var result = SafeResourceLoader.load(_resource_path("contains_inline_scripts.tres"))
	assert_that(result).is_null()
	

func test_load_resource_with_duplicate_path_attribute_is_blocked():
	var result = SafeResourceLoader.load(_resource_path("contains_duplicate_path_attributes.tres"))
	assert_that(result).is_null()


func test_load_resource_with_unsafe_external_references_is_blocked():
	var result = SafeResourceLoader.load(_resource_path("contains_path_outside_res.tres"))
	assert_that(result).is_null()


func test_load_resource_with_comment_hack_is_blocked():
	var result = SafeResourceLoader.load(_resource_path("obscures_attributes_with_comments.tres"))
	assert_that(result).is_null()
