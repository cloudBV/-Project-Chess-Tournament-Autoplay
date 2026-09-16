extends CanvasLayer

signal next_game_pressed
signal restart_pressed
signal auto_advance_toggled(is_on : bool)
signal category_toggled(category : String , is_on : bool)

@onready var next_game_button = $NextGameButton
@onready var restart_button = $RestartButton
@onready var game_info_label = $GameInfoLabel
@onready var move_counter_label = $MoveCounterLabel
@onready var category_label = $CategoryLabel
@onready var auto_advance_toggle = $AutoAdvanceToggle
@onready var settings_button = $SettingsButton
@onready var settings_menu = $SettingsMenu
@onready var category_list = $SettingsMenu/ScrollContainer/CategoryList
@onready var close_button = $SettingsMenu/CloseButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_game_button.pressed.connect(func(): next_game_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	auto_advance_toggle.toggled.connect(func(is_on): auto_advance_toggled.emit(is_on))
	auto_advance_toggle.button_pressed = false
	settings_button.pressed.connect(func(): settings_menu.visible = true)
	close_button.pressed.connect(func(): settings_menu.visible = false)
	settings_menu.visible = false

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

func set_category_text(text : String):
	category_label.text = text

func set_game_info(text : String):
	game_info_label.text = text

func set_move_counter(text : String):
	move_counter_label.text = text

func set_auto_advance_label(is_on : bool):
	auto_advance_toggle.text = 'Auto Advance : ON' if is_on else 'Auto Advance : off'

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
