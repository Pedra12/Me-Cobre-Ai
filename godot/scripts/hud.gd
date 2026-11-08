extends CanvasLayer

var player
var game
var health_label: Label
var ammo_label: Label
var wave_label: Label
var score_label: Label
var banner: Label
var menu: Control
var joystick: Panel
var knob: Panel
var shoot_button: Button
var aim_button: Button
var joy_touch := -1
var look_touch := -1
var joy_center := Vector2.ZERO
var joy_value := Vector2.ZERO
var look_last := Vector2.ZERO
var screen_scale := 1.0

func setup(p: Node, g: Node) -> void:
	player = p
	game = g
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	health_label = _label(root, "VIDA 100", Vector2(22, 18), 25)
	wave_label = _label(root, "HORDA 0", Vector2(22, 50), 18)
	score_label = _label(root, "PONTOS 0", Vector2(22, 74), 16)
	ammo_label = _label(root, "RIFLE 30 / 120", Vector2(0, 0), 22)
	ammo_label.anchor_left = 1.0
	ammo_label.anchor_right = 1.0
	ammo_label.offset_left = -250
	ammo_label.offset_right = -20
	ammo_label.offset_top = 18
	ammo_label.offset_bottom = 48
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var cross := Label.new()
	cross.text = "⊕"
	cross.add_theme_font_size_override("font_size", 34)
	cross.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-15, -22)
	root.add_child(cross)
	banner = _label(root, "", Vector2(0, 0), 30)
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -180
	banner.offset_right = 180
	banner.offset_top = 110
	banner.offset_bottom = 155
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joystick = Panel.new()
	joystick.position = Vector2(35, -180)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.size = Vector2(145, 145)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(joystick, Color(0.75, 0.82, 0.78, 0.16), 72)
	root.add_child(joystick)
	knob = Panel.new()
	knob.position = Vector2(43, 43)
	knob.size = Vector2(59, 59)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(knob, Color(0.82, 0.9, 0.82, 0.38), 30)
	joystick.add_child(knob)
	_make_button(root, "ATIRAR", Vector2(-125, -150), Vector2(104, 104), _on_shoot_down, _on_shoot_up, true)
	shoot_button = get_node_or_null("ShootButton") as Button
	_make_button(root, "MIRAR", Vector2(-245, -118), Vector2(78, 78), _on_aim_down, _on_aim_up, true)
	aim_button = get_node_or_null("AimButton") as Button
	_make_button(root, "PULAR", Vector2(-225, -42), Vector2(68, 68), func(): player.request_jump(), func(): pass, false)
	_make_button(root, "REC", Vector2(-310, -32), Vector2(64, 64), func(): player.request_reload(), func(): pass, false)
	_make_button(root, "1", Vector2(-90, -270), Vector2(48, 42), func(): player.select_weapon(0), func(): pass, false)
	_make_button(root, "2", Vector2(-38, -270), Vector2(48, 42), func(): player.select_weapon(1), func(): pass, false)
	_make_button(root, "3", Vector2(14, -270), Vector2(48, 42), func(): player.select_weapon(2), func(): pass, false)
	var pause := _make_button(root, "Ⅱ", Vector2(-64, 18), Vector2(48, 48), func(): _pause_game(), func(): pass, false)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.offset_left = -64
	pause.offset_right = -16
	pause.offset_top = 18
	pause.offset_bottom = 66
	_make_menu(root)

func _label(parent: Control, text_value: String, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.93, 0.95, 0.86))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l

func _style_panel(panel: Panel, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.32)
	panel.add_theme_stylebox_override("panel", style)

func _make_button(parent: Control, text_value: String, offset: Vector2, size: Vector2, down: Callable, up: Callable, hold: bool) -> Button:
	var b := Button.new()
	b.text = text_value
	b.size = size
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = offset.x
	b.offset_right = offset.x + size.x
	b.offset_top = offset.y
	b.offset_bottom = offset.y + size.y
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.12, 0.70)
	style.border_color = Color(0.8, 0.9, 0.8, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(48 if size.x > 70 else 14)
	b.add_theme_stylebox_override("normal", style)
	var pressed_style: StyleBoxFlat = style.duplicate()
	pressed_style.bg_color = Color(0.22, 0.40, 0.20, 0.92)
	b.add_theme_stylebox_override("pressed", pressed_style)
	parent.add_child(b)
	if hold:
		b.button_down.connect(down)
		b.button_up.connect(up)
	else:
		b.pressed.connect(down)
	return b

func _make_menu(root: Control) -> void:
	menu = Panel.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_panel(menu, Color(0.015, 0.025, 0.025, 0.94), 0)
	root.add_child(menu)
	var title := Label.new()
	title.text = "COMBATE ZOMBIE 3D"
	title.position = Vector2(0, 0)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -260
	title.offset_right = 260
	title.offset_top = 110
	title.offset_bottom = 165
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.63, 1.0, 0.36))
	menu.add_child(title)
	var play := Button.new()
	play.text = "JOGAR SOLO"
	play.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	play.offset_left = -130
	play.offset_right = 130
	play.offset_top = -15
	play.offset_bottom = 48
	play.add_theme_font_size_override("font_size", 22)
	menu.add_child(play)
	play.pressed.connect(func():
		menu.hide()
		game.start_game()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not OS.has_feature("android") else Input.MOUSE_MODE_VISIBLE
	)

func show_menu() -> void:
	menu.show()
	if menu.get_child_count() > 0 and menu.get_child(0) is Label:
		menu.get_child(0).text = "COMBATE ZOMBIE 3D"

func show_game_over() -> void:
	menu.show()
	if menu.get_child_count() > 0 and menu.get_child(0) is Label:
		menu.get_child(0).text = "VOCÊ FOI DERROTADO"

func set_game_visible(value: bool) -> void:
	if value:
		menu.hide()
	else:
		menu.show()

func update_status(health: float, wave: int, score: int, count: int) -> void:
	health_label.text = "VIDA %d" % int(health)
	wave_label.text = "HORDA %d  |  ZUMBIS %d" % [wave, count]
	score_label.text = "PONTOS %d" % score
	var weapon: Dictionary = player.WEAPONS[player.weapon_index]
	var a: Dictionary = player.ammo[player.weapon_index]
	ammo_label.text = "%s   %d / %d" % [weapon.name, a.mag, a.reserve]

func show_banner(value: String) -> void:
	banner.text = value
	get_tree().create_timer(2.0).timeout.connect(func(): banner.text = "")

func _on_shoot_down() -> void:
	player.set_shooting(true)

func _on_shoot_up() -> void:
	player.set_shooting(false)

func _on_aim_down() -> void:
	player.set_aiming(true)

func _on_aim_up() -> void:
	player.set_aiming(false)

func _pause_game() -> void:
	get_tree().paused = true
	var popup := AcceptDialog.new()
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	popup.dialog_text = "Partida pausada"
	add_child(popup)
	popup.confirmed.connect(func(): get_tree().paused = false)
	popup.popup_centered()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player) or menu.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.42 and event.position.y > get_viewport().get_visible_rect().size.y * 0.48:
				joy_touch = event.index
				joy_center = joystick.global_position + joystick.size * 0.5
				_update_joystick(event.position)
			elif event.position.x > get_viewport().get_visible_rect().size.x * 0.42 and not _over_action_buttons(event.position):
				look_touch = event.index
				look_last = event.position
		else:
			if event.index == joy_touch:
				joy_touch = -1
				joy_value = Vector2.ZERO
				knob.position = Vector2(43, 43)
				player.set_move_input(Vector2.ZERO)
			if event.index == look_touch:
				look_touch = -1
	if event is InputEventScreenDrag:
		if event.index == joy_touch:
			_update_joystick(event.position)
		elif event.index == look_touch:
			player.add_look(event.position - look_last)
			look_last = event.position

func _over_action_buttons(point: Vector2) -> bool:
	var size := get_viewport().get_visible_rect().size
	return point.x > size.x - 330 and point.y > size.y - 310

func _update_joystick(point: Vector2) -> void:
	var delta := (point - joy_center) / 55.0
	joy_value = delta.limit_length(1.0)
	knob.position = Vector2(43, 43) + joy_value * 40.0
	player.set_move_input(Vector2(joy_value.x, joy_value.y))
