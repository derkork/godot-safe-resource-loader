extends CenterContainer

@onready var _result_label:Label = %ResultLabel
@onready var _file_dialog:FileDialog = %FileDialog

var _load_safely:bool = false


func _on_open_unsafe_button_pressed():
	_load_safely = false
	_on_open_button_pressed()
	

func _on_open_safe_button_pressed():
	_load_safely = true
	_on_open_button_pressed()
	

func _on_open_button_pressed():
	_file_dialog.current_dir = ProjectSettings.globalize_path("res://safe_resource_loader_example")
	_file_dialog.popup_centered()


func _on_file_dialog_file_selected(path):
	# Load the file through the safe or unsafe resource loader, depending on which button was pressed
	var loaded:Resource = null
	if _load_safely:
		loaded = SafeResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)			


	if loaded == null:		
		_result_label.text = "Resource was not loaded."
	else:
		_result_label.text = "Resource was loaded."
		



