class_name MachinePanel
extends PanelContainer

@onready var machine_name_label: Label = $Margin/VBox/MachineName
@onready var recipe_label: Label = $Margin/VBox/Recipe
@onready var output_label: Label = $Margin/VBox/Output
@onready var stats_header: Label = $Margin/VBox/StatsHeader
@onready var stats_label: Label = $Margin/VBox/Stats
@onready var ingredients_header: Label = $Margin/VBox/IngredientsHeader
@onready var ingredients_label: Label = $Margin/VBox/Ingredients
@onready var availability_label: Label = $Margin/VBox/Availability
@onready var progress_label: Label = $Margin/VBox/Progress
@onready var controls_header: Label = $Margin/VBox/ControlsHeader
@onready var controls_label: Label = $Margin/VBox/Controls
@onready var generic_sections: VBoxContainer = $Margin/VBox/GenericSections


func set_panel_data(data: Dictionary) -> void:
	if data.is_empty():
		visible = false
		return

	visible = true
	machine_name_label.text = str(data.get("machine_name", "Machine"))
	if data.has("sections"):
		_set_generic_panel_data(data)
	else:
		_set_encoder_panel_data(data)

	var controls_text := str(data.get("controls_text", ""))
	controls_header.visible = not controls_text.is_empty()
	controls_label.visible = not controls_text.is_empty()
	controls_label.text = controls_text


func _set_encoder_panel_data(data: Dictionary) -> void:
	generic_sections.visible = false
	_clear_generic_sections()
	recipe_label.visible = true
	output_label.visible = true
	recipe_label.text = "Recipe: %s" % str(data.get("selected_recipe_name", "Unavailable"))
	output_label.text = "Output: %s" % str(data.get("output_name", "Unavailable"))

	var output_stats: Dictionary = data.get("output_stats", {})
	stats_header.visible = not output_stats.is_empty()
	stats_label.visible = not output_stats.is_empty()
	stats_label.text = _format_stats(output_stats)

	var ingredients: Array = data.get("ingredients", [])
	ingredients_header.visible = not ingredients.is_empty()
	ingredients_label.visible = not ingredients.is_empty()
	ingredients_label.text = _format_ingredients(ingredients)

	availability_label.visible = true
	var is_running: bool = data.get("is_running", false)
	var can_encode: bool = data.get("can_encode", false)
	if is_running:
		availability_label.text = "Machine running"
	elif can_encode:
		availability_label.text = "Ready to encode"
	else:
		availability_label.text = "Missing ingredients"

	progress_label.visible = is_running
	progress_label.text = "Encoding: %d%%" % int(data.get("progress_percent", 0))


func _set_generic_panel_data(data: Dictionary) -> void:
	recipe_label.visible = false
	output_label.visible = false
	stats_header.visible = false
	stats_label.visible = false
	ingredients_header.visible = false
	ingredients_label.visible = false
	progress_label.visible = false

	var status_text := str(data.get("status_text", ""))
	availability_label.visible = not status_text.is_empty()
	availability_label.text = status_text

	generic_sections.visible = true
	_clear_generic_sections()
	var sections: Array = data.get("sections", [])
	for section: Dictionary in sections:
		var title := str(section.get("title", ""))
		if not title.is_empty():
			var header := Label.new()
			header.text = title
			header.add_theme_color_override("font_color", Color(0.65, 0.84, 1.0, 1.0))
			header.add_theme_font_size_override("font_size", 16)
			generic_sections.add_child(header)

		var lines: Array = section.get("lines", [])
		if not lines.is_empty():
			var body := Label.new()
			body.text = "\n".join(PackedStringArray(lines))
			body.add_theme_font_size_override("font_size", 14)
			generic_sections.add_child(body)


func _clear_generic_sections() -> void:
	for child in generic_sections.get_children():
		child.free()


func _format_stats(stats: Dictionary) -> String:
	var lines: PackedStringArray = []
	var stat_definitions: Array[Array] = [
		["clarity", "Clarity"],
		["intensity", "Intensity"],
		["stability", "Stability"],
		["duration", "Duration"],
		["heat", "Heat"],
		["value", "Value"],
		["corruption", "Corruption"],
	]
	for definition in stat_definitions:
		var key: String = definition[0]
		if not stats.has(key):
			continue
		var value_text := str(stats[key])
		if key == "value":
			value_text = "$%s" % value_text
		lines.append("%s: %s" % [definition[1], value_text])
	return "\n".join(lines)


func _format_ingredients(ingredients: Array) -> String:
	var lines: PackedStringArray = []
	for ingredient: Dictionary in ingredients:
		var line := "%s: %d / %d" % [
			str(ingredient.get("display_name", ingredient.get("item_id", "Unknown"))),
			int(ingredient.get("owned_amount", 0)),
			int(ingredient.get("required_amount", 0)),
		]
		if ingredient.get("is_missing", false):
			line += " MISSING"
		lines.append(line)
	return "\n".join(lines)
