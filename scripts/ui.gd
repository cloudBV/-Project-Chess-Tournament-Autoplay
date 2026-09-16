extends CanvasLayer

signal next_game_pressed
signal restart_pressed
signal auto_advance_toggled(is_on : bool)
signal category_toggled(category : String , is_on : bool)

signal filter_mode_changed(mode)
signal time_control_toggled(time_control : String, is_on : bool)

@onready var next_game_button = $NextGameButton
@onready var restart_button = $RestartButton
@onready var game_info_label = $GameInfoLabel
@onready var move_counter_label = $MoveCounterLabel
@onready var category_label = $CategoryLabel
@onready var time_control_label = $TimeControlLabel
@onready var auto_advance_toggle = $AutoAdvanceToggle
@onready var categories_button = $CategoriesButton

@onready var timecontrol_button = $TimeControlButton

@onready var menu = $Menu
@onready var category_list = $Menu/ScrollContainer/CategoryList
@onready var close_button = $Menu/CloseButton

@onready var credit_button = $CreditButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	credit_button.pressed.connect(func(): OS.shell_open('https://cloudbv.itch.io'))
	
	next_game_button.pressed.connect(func(): next_game_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	auto_advance_toggle.toggled.connect(func(is_on): auto_advance_toggled.emit(is_on))
	auto_advance_toggle.button_pressed = false
	
	categories_button.pressed.connect(func(): 
		filter_mode_changed.emit('category')
		menu.visible = true
		)

	timecontrol_button.pressed.connect(func(): 
		filter_mode_changed.emit('time_control')
		menu.visible = true
		)
	
	#categories_button.pressed.connect(func(): switch_mode(CATEGORY))
	#timecontrol_button.pressed.connect(func(): switch_mode(TIMECONTROL))
	#switch_mode(CATEGORY)

	close_button.pressed.connect(func(): menu.visible = false)
	menu.visible = false

#func switch_mode(mode):
#	pass

func build_category_checkboxes(all_categories : Dictionary, enabled: Array):
	for child in category_list.get_children():
		child.queue_free()
	
	for category_key in all_categories.keys():
		var checkbox = CheckBox.new()
		checkbox.text = all_categories[category_key]
		checkbox.button_pressed = enabled.has(category_key)
		checkbox.add_theme_font_size_override('font_size' , 36)
		
		checkbox.mouse_filter = Control.MOUSE_FILTER_PASS
		#checkbox.custom_minimum_size = Vector2(400,400)
		#checkbox.expand_icon = true
		
		checkbox.toggled.connect(func(is_on): category_toggled.emit(category_key, is_on))
		category_list.add_child(checkbox)

func build_time_control_checkboxes(all_time_controls : Dictionary, enabled : Array):
	for child in category_list.get_children():
		child.queue_free()
	
	for tc_key in all_time_controls.keys():
		var checkbox = CheckBox.new()
		checkbox.text = all_time_controls[tc_key]
		checkbox.button_pressed = enabled.has(tc_key)
		checkbox.add_theme_font_size_override('font_size' , 36)
		
		checkbox.mouse_filter = Control.MOUSE_FILTER_PASS
		
		checkbox.toggled.connect(func(is_on) : time_control_toggled.emit(tc_key , is_on))
		category_list.add_child(checkbox)

func set_category_text(text : String):
	category_label.text = text

func set_time_control_text(text : String):
	time_control_label.text = text

func set_game_info(text : String):
	game_info_label.text = text

func set_move_counter(text : String):
	move_counter_label.text = text

func set_auto_advance_label(is_on : bool):
	auto_advance_toggle.text = 'Auto Advance : ON' if is_on else 'Auto Advance : off'

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
