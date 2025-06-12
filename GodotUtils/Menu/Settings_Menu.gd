class_name SettingsMenu extends CanvasLayer
const Load_Path : String = "res://Menu/Settings_Menu.tscn"

#region Focusable Menu
const Default_Process := PROCESS_MODE_ALWAYS
var prev : Node
var last_focused : Control

func resume_focus() -> void:
	process_mode = Default_Process
	if last_focused != null:
		last_focused.grab_focus()

func pause_focus() -> void:
	last_focused = get_viewport().gui_get_focus_owner()
	process_mode = PROCESS_MODE_DISABLED

func open_menu(prev_menu : Node) -> void:
	prev = prev_menu
	if prev_menu.has_method("pause_focus"):
		prev_menu.pause_focus()
	#grab focus to default
		
func return_to_prev() -> void:
	if prev == null: return
	prev.resume_focus()
	queue_free()
#endregion
	
#region Settings
@export var volume : HSlider
@export var language_selector : OptionButton

func volume_changed(value : float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	
func _set_locales() -> void:
	for loc : String in TranslationServer.get_loaded_locales():
		language_selector.add_item(loc)
		
	var locale_idx : int = TranslationServer.get_loaded_locales().find(TranslationServer.get_locale())
	if locale_idx == -1:
		locale_idx = TranslationServer.get_loaded_locales().find("en")
	language_selector.selected = locale_idx
		
func _change_locale(idx : int) -> void:
	TranslationServer.set_locale(TranslationServer.get_loaded_locales()[idx])
#endregion
	
func _enter_tree() -> void:
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	volume.value_changed.connect(volume_changed)
	_set_locales()
	language_selector.item_selected.connect(_change_locale)
	pass
