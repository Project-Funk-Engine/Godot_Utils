class_name Remap extends CanvasLayer
const Load_Path : String = "res://Remapping/Remap.tscn"
@export var registered_inputs : Array[String]

@export var tabs : TabContainer
@export var keyboard_container : VBoxContainer
@export var controller_container : VBoxContainer
@export var return_button : Button

func _enter_tree() -> void:
	for input_map : String in registered_inputs:
		if !InputMap.has_action(input_map): continue
		_add_input_remaps(input_map)
	tabs.tab_changed.connect(_tab_changed)
	return_button.pressed.connect(return_to_prev)
	
func _process(_delta: float) -> void:
	if waiting_for_input && input_timer != null:
		countdown_label.text = "%1.0f" % input_timer.time_left
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !waiting_for_input:
		return_to_prev()
		return
	
	if event.is_action_pressed("ui_cancel") and waiting_for_input:
		input_timer.stop()
		_input_timer_timeout()
	elif waiting_for_input:
		if (event is InputEventMouseMotion): return
		_remap_event(event)
	elif event.is_action_pressed("cancel"):
		print_debug("Success")
		
static func _input_as_string(event : InputEvent) -> String:
	var result : String
	if (event is InputEventKey):
		result = (event as InputEventKey).as_text()
	elif (event is InputEventMouseButton):
		result = (event as InputEventMouseButton).as_text()
	elif (event is InputEventJoypadButton):
		result = (event as InputEventJoypadButton).as_text()
	elif (event is InputEventJoypadMotion):
		result = (event as InputEventJoypadMotion).as_text()
	else:
		return "INVALID"
		
	return result.substr(0, result.find("(")).strip_edges().to_upper().replace(" ", "_")
	
func _tab_changed(idx : int) -> void:
	controller_input = idx == 1

func _add_input_remaps(input_map : String) -> void:
	if InputMap.action_get_events(input_map).size() < 1: return
	
	var outer_container : HBoxContainer = HBoxContainer.new()
	keyboard_container.add_child(outer_container)
	var kb_label : Label = Label.new()
	kb_label.text = input_map
	outer_container.add_child(kb_label)
	
	var outer_cont_container : HBoxContainer = HBoxContainer.new()
	controller_container.add_child(outer_cont_container)
	var cont_label : Label = Label.new()
	cont_label.text = input_map
	outer_cont_container.add_child(cont_label)
	
	for event : InputEvent in InputMap.action_get_events(input_map):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			_add_input_button(event, outer_cont_container, input_map)
		else:
			_add_input_button(event, outer_container, input_map)
		
func _add_input_button(event : InputEvent, parent : Node, input_map : String) -> void:
	var button : Button = Button.new()
	button.text = _input_as_string(event)
	button.pressed.connect(_begin_wait_for_input.bind(button, event, input_map))
	parent.add_child(button)
	
var waiting_for_input : bool = false
var controller_input : bool = false
const Wait_Time : int = 5
const Joy_Threshold : float = .2
var input_timer : Timer = null

@export var countdown_cont : CenterContainer
@export var countdown_label : Label

var current_button : Button
var current_event : InputEvent
var current_mapping : String

func _remap_event(event : InputEvent) -> void:
	if (InputMap.action_has_event(current_mapping, event)): return
	if (!controller_input and (event is InputEventJoypadButton or event is InputEventJoypadMotion)): return
	if (controller_input and !(event is InputEventJoypadButton or event is InputEventJoypadMotion)): return
	if (event is InputEventJoypadMotion and (event as InputEventJoypadMotion).get_axis_value() < Joy_Threshold): return
	
	InputMap.action_erase_event(current_mapping, current_event)
	InputMap.action_add_event(current_mapping, event)
	current_button.text = _input_as_string(event)
	current_button.pressed.disconnect(_begin_wait_for_input)
	current_button.pressed.connect(_begin_wait_for_input.bind(current_button, event, current_mapping))

	input_timer.stop()
	_input_timer_timeout()

func _begin_wait_for_input(button : Button, old_event : InputEvent, input_map : String) -> void:
	waiting_for_input = true
	input_timer = Timer.new()
	add_child(input_timer)
	input_timer.start(Wait_Time)
	input_timer.timeout.connect(_input_timer_timeout)
	countdown_cont.visible = true
	current_button = button
	current_event = old_event
	current_mapping = input_map
	tabs.process_mode = PROCESS_MODE_DISABLED
	
	
func _input_timer_timeout() -> void:
	input_timer.queue_free()
	waiting_for_input = false
	countdown_cont.visible = false
	tabs.process_mode = PROCESS_MODE_ALWAYS

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
	tabs.get_tab_bar().grab_focus()

func return_to_prev() -> void:
	if prev == null: return
	prev.resume_focus()
	queue_free()
#endregion
		

		
