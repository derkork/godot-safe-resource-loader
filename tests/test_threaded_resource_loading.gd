extends GdUnitTestSuite


func _resource_path(tres_file: String):
	return ProjectSettings.globalize_path("res://tests/data/%s" % tres_file)


func test_threaded_load_safe_resource_works():
	# Request the threaded load
	var error = SafeResourceLoader.load_threaded_request(_resource_path("safe.tres"))
	assert_that(error).is_equal(OK)

	# Check the status
	var progress = []
	var status = SafeResourceLoader.load_threaded_get_status(_resource_path("safe.tres"), progress)

	# Wait until the resource is loaded
	while status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = SafeResourceLoader.load_threaded_get_status(_resource_path("safe.tres"), progress)

	# Verify the resource was loaded successfully
	assert_that(status).is_equal(ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED)

	# Get the loaded resource
	var result = SafeResourceLoader.load_threaded_get(_resource_path("safe.tres"))
	assert_that(result).is_not_null()


func test_threaded_load_resource_with_inline_script_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_inline_scripts.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_duplicate_path_attribute_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_duplicate_path_attributes.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_unsafe_external_references_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_path_outside_res.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_comment_hack_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("obscures_attributes_with_comments.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_extra_line_breaks_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_extra_line_breaks.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_legacy_string_names_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_legacy_string_names.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_node_paths_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_node_paths.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)


func test_threaded_load_resource_with_string_names_is_blocked():
	var error = SafeResourceLoader.load_threaded_request(_resource_path("contains_string_names.tres"))
	assert_that(error).is_equal(ERR_INVALID_DATA)
