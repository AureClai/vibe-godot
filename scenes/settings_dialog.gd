# res://addons/vibe_godot/settings_dialog.gd
extends Window

# Signal que nous enverrons au plugin principal avec les nouvelles valeurs
signal settings_saved(api_key, model_name)

# Références aux nœuds de l'interface
@onready var api_key_edit = $MarginContainer/VBoxContainer/GridContainer/ApiKeyEdit
@onready var model_name_edit = $MarginContainer/VBoxContainer/GridContainer/ModelNameEdit
@onready var save_button = $MarginContainer/VBoxContainer/SaveButton

func _ready():
	# Connecter le bouton "Enregistrer" à notre fonction interne
	save_button.pressed.connect(_on_save_button_pressed)
	# Cacher la fenêtre quand on clique sur la croix (au lieu de la détruire)
	close_requested.connect(hide)

# Appelée lorsque l'utilisateur clique sur notre bouton "Enregistrer"
func _on_save_button_pressed():
	# On émet notre signal personnalisé avec les valeurs des champs
	settings_saved.emit(api_key_edit.text, model_name_edit.text)
	# On cache la fenêtre après avoir sauvegardé
	hide()

# Fonction publique que le plugin appellera pour initialiser les champs
func set_fields(api_key: String, model_name: String):
	api_key_edit.text = api_key
	model_name_edit.text = model_name


func _on_close_requested() -> void:
	hide()
