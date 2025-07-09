@tool
extends EditorPlugin

const SettingsDialog = preload("res://addons/vibe-godot/scenes/settings_dialog.tscn")
# Le chemin vers notre propre fichier de configuration
const SETTINGS_FILE = "res://addons/vibe_godot/settings.cfg"
var settings_dialog_instance

const CodeGenDockScene = preload("res://addons/vibe-godot/scenes/vibe_godot_dock.tscn")

var dock_instance

var script_path_to_modify: String = ""

func _enter_tree():
	add_tool_menu_item("Paramètres Vibe Godot", Callable(self, "_on_settings_menu_pressed"))
	# Création de l'instance de l'UI
	dock_instance = CodeGenDockScene.instantiate()
	
	# Ajout du dock à droite de l'éditeur
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock_instance)
	
	# Connection des signaux
	var generate_button = dock_instance.get_node("MarginContainer/VBoxContainer/GenerateButton")
	var copy_button = dock_instance.get_node("MarginContainer/VBoxContainer/CopyButton")
	var apply_button = dock_instance.get_node("MarginContainer/VBoxContainer/ApplyButton")
	
	generate_button.pressed.connect(_on_generate_code_pressed)
	copy_button.pressed.connect(_on_copy_code_pressed)
	apply_button.pressed.connect(_on_apply_changes_pressed)
	
	GeminiAPI.response_received.connect(_on_gemini_response_received)
	
func _exit_tree():
	remove_tool_menu_item("Paramètres Vibe Godot")
	# On se déconnecte du signal global pour éviter les erreurs.
	if GeminiAPI.is_connected("response_received",Callable(self,"_on_gemini_response_received")):
		GeminiAPI.response_received.disconnect(Callable(self,"_on_gemini_response_received"))

	# On nettoie proprement l'interface.
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.free()
		
func _on_settings_menu_pressed():
	if not is_instance_valid(settings_dialog_instance):
		settings_dialog_instance = SettingsDialog.instantiate()
		var save_button = settings_dialog_instance.find_child("SaveButton")
		save_button.pressed.connect(_on_save_settings_pressed)
		add_child(settings_dialog_instance)

	# On charge la configuration pour pré-remplir les champs
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE)
	
	var api_key_edit = settings_dialog_instance.find_child("ApiKeyEdit")
	var model_name_edit = settings_dialog_instance.find_child("ModelNameEdit")
	
	api_key_edit.text = config.get_value("api", "api_key", "")
	model_name_edit.text = config.get_value("api", "model_name", "gemini-1.5-flash")
	
	settings_dialog_instance.popup_centered()

func _on_save_settings_pressed():
	if not is_instance_valid(settings_dialog_instance):
		return

	var api_key_edit = settings_dialog_instance.find_child("ApiKeyEdit")
	var model_name_edit = settings_dialog_instance.find_child("ModelNameEdit")
	
	# On sauvegarde les valeurs dans notre fichier de configuration
	var config = ConfigFile.new()
	config.set_value("api", "api_key", api_key_edit.text)
	config.set_value("api", "model_name", model_name_edit.text)
	
	# On écrit les changements dans le fichier sur le disque
	var error = config.save(SETTINGS_FILE)
	if error != OK:
		push_error("Impossible de sauvegarder les paramètres de Vibe Godot.")
	
	print("Paramètres de Vibe Godot enregistrés.")
	settings_dialog_instance.hide()
	
# --- Logique de l'outil ---

func _on_generate_code_pressed():
	var prompt_input = dock_instance.get_node("MarginContainer/VBoxContainer/PromptInput")
	var result_code_edit = dock_instance.get_node("MarginContainer/VBoxContainer/ResultCode")
	var apply_button = dock_instance.get_node("MarginContainer/VBoxContainer/ApplyButton")
	var user_prompt = prompt_input.text
	
	# On réinitialise l'état à chaque nouvelle demande.
	script_path_to_modify = ""
	apply_button.disabled = true

	if user_prompt.is_empty():
		result_code_edit.text = "Veuillez entrer une description."
		return

	# 1. On utilise une expression régulière pour trouver une référence de script.
	var regex = RegEx.new()
	# Le motif recherche un @ suivi de caractères alphanumériques (y compris '_') se terminant par .gd
	regex.compile("@([\\w_]+\\.gd)") 
	var result = regex.search(user_prompt)

	var final_prompt = ""

	# 2. On vérifie si une référence a été trouvée.
	if result:
		# On extrait le nom du fichier (le premier groupe capturé par les parenthèses).
		var filename = result.get_string(1)
		var filepath = "res://" + filename
		
		script_path_to_modify = filepath
		
		# On s'assure que le fichier existe avant d'essayer de le lire.
		if not FileAccess.file_exists(filepath):
			result_code_edit.text = "Erreur : Le fichier '%s' n'a pas été trouvé." % filepath
			return
			
		# 3. On lit le contenu du script existant.
		var file = FileAccess.open(filepath, FileAccess.READ)
		var script_content = file.get_as_text()
		file.close()

		# On nettoie le prompt utilisateur en enlevant la référence @script.gd.
		var clean_user_request = user_prompt.replace("@" + filename, "").strip_edges()
		
		# 4. On construit un prompt avancé pour la modification de code.
		final_prompt = """
Tu es un expert en développement sur Godot Engine. Ta tâche est de proposer une version modifiée et améliorée d'un script GDScript existant, en suivant la demande de l'utilisateur.
Ne retourne QUE le code complet du script modifié. N'ajoute aucune phrase d'introduction, d'explication ou de conclusion. N'utilise pas de blocs de code markdown.

DEMANDE DE L'UTILISATEUR :
---
%s
---

SCRIPT EXISTANT (`%s`) :
---
%s
---

SCRIPT MODIFIÉ PROPOSÉ :
""" % [clean_user_request, filename, script_content]

	else:
		# Comportement original si aucune référence de script n'est trouvée.
		final_prompt = """
En GDScript pour Godot 4, écris un code qui accomplit la tâche suivante.
Ne fournis que le code, sans phrases d'explication avant ou après.
N'utilise pas de blocs de code markdown.
La tâche est : "%s"
""" % user_prompt

	# On envoie le prompt final à l'API.
	result_code_edit.text = "Analyse et génération en cours..."
	GeminiAPI.ask_gemini(final_prompt)

func _on_gemini_response_received(content: String):
	var result_code_edit = dock_instance.get_node("MarginContainer/VBoxContainer/ResultCode")
	var apply_button = dock_instance.get_node("MarginContainer/VBoxContainer/ApplyButton")

	# On met à jour le CodeEdit avec le résultat reçu.
	result_code_edit.text = content
	
	if not script_path_to_modify.is_empty():
		apply_button.disabled = false

func _on_apply_changes_pressed():
	if script_path_to_modify.is_empty():
		push_error("Aucun chemin de script à modifier n'est défini.")
		return

	var result_code_edit = dock_instance.get_node("MarginContainer/VBoxContainer/ResultCode")
	var apply_button = dock_instance.get_node("MarginContainer/VBoxContainer/ApplyButton")
	
	var new_content = result_code_edit.text
	
	# On ouvre le fichier en mode écriture, ce qui l'écrase.
	var file = FileAccess.open(script_path_to_modify, FileAccess.WRITE)
	if file:
		file.store_string(new_content)
		file.close()
		
		print("Le script '%s' a été modifié avec succès." % script_path_to_modify)
		
		# On force Godot à ré-importer le script pour voir les changements immédiatement.
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("Impossible d'ouvrir le fichier en écriture : " + script_path_to_modify)

	# On réinitialise l'état pour éviter une modification accidentelle.
	apply_button.disabled = true
	script_path_to_modify = ""

func _on_copy_code_pressed():
	var result_code_edit = dock_instance.get_node("MarginContainer/VBoxContainer/ResultCode")

	# Copie le contenu du champ de résultat dans le presse-papiers.
	DisplayServer.clipboard_set(result_code_edit.text)
