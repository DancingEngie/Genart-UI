extends Node

signal image_generator_params_updated


var settings: AppSettings
var error_notification: Control


func save():
	ResourceSaver.save(settings, "user://settings.tres")

func _init() -> void:
	
	# The first time loads the default settings
	if not ResourceLoader.exists("user://settings.tres"):
		settings = load("res://settings/default_settings.tres")
	else:
		settings = load("user://settings.tres")
	
func _enter_tree() -> void:
	
	var textures = settings \
		.image_generator_params \
		.individual_generator_params \
		.populator_params.textures
	
	var texture_group: IndividualsTextureGroup = null
	
	for group in settings.individuals_texture_groups:
		if group.name == settings.default_texture_group_name:
			texture_group = group
			break
			
	if texture_group == null:
		push_error("Unable to find texture group named: %s" % settings.default_texture_group_name)
	
	# Loads default textures
	for default_texture in texture_group.textures:
		var renderer_texture = RendererTexture.load_from_texture(default_texture)
		textures.append(renderer_texture)
	
	# Loads default target texture
	var target_texture = RendererTexture.load_from_texture(settings.default_target_texture)
	
	if target_texture == null or not target_texture.is_valid():
		Notifier.notify_error("Unable to load default target texture")
		return
	
	settings.image_generator_params.individual_generator_params.target_texture = target_texture
	
	Globals.settings.image_generator_params.setup_changed_signals()
	Globals.settings.image_generator_params.changed.connect(_image_generator_params_changed)
	
func _exit_tree() -> void:

	# Clears previous textures
	var textures = settings \
			.image_generator_params \
			.individual_generator_params \
			.populator_params.textures
	
	textures.clear()
	
	settings \
	.image_generator_params \
	.weight_texture_generator_params \
	.user_weight_texture = null
	
	save()
	

func image_generator_params_set_preset(preset_type: ImageGeneratorParams.Type):
	
	# Loads any of the presets and duplicates
	var preset: ImageGeneratorParams = null
	match preset_type:
		ImageGeneratorParams.Type.FAST:
			preset = load("res://settings/image_generator_params/fast_image_generator_params.tres").duplicate(true)
		ImageGeneratorParams.Type.PERFORMANCE:
			preset = load("res://settings/image_generator_params/performant_image_generator_params.tres").duplicate(true)
		ImageGeneratorParams.Type.QUALITY:
			preset = load("res://settings/image_generator_params/quality_image_generator_params.tres").duplicate(true)
	
	# Copies runtime params
	var previous_params = Globals.settings.image_generator_params
	preset.individual_generator_params.target_texture = previous_params.individual_generator_params.target_texture
	preset.individual_generator_params.populator_params = previous_params.individual_generator_params.populator_params
	preset.weight_texture_generator_params.user_weight_texture = previous_params.weight_texture_generator_params.user_weight_texture
	# Updates the individual generator params
	Globals.settings.image_generator_params = preset
	image_generator_params_updated.emit()
	
	# Connects changed signals
	preset.setup_changed_signals()
	preset.changed.connect(_image_generator_params_changed)

func _image_generator_params_changed():
	Globals.settings.image_generator_params.type = ImageGeneratorParams.Type.CUSTOM
