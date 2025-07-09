# GeminiAPI.gd
@tool
extends Node

const SETTINGS_FILE = "res://addons/vibe_godot/settings.cfg"

signal response_received(content)

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed)


func ask_gemini(prompt_text: String):
	# On charge notre fichier de configuration
	var config = ConfigFile.new()
	# On ne fait rien si le fichier n'existe pas, get_value fournira les valeurs par défaut
	config.load(SETTINGS_FILE) 
	
	# On récupère les valeurs. Le 3ème argument est la valeur par défaut.
	var api_key = config.get_value("api", "api_key", "")
	var model_name = config.get_value("api", "model_name", "gemini-2.5-flash")

	if api_key.is_empty():
		var msg = "Clé API Gemini non configurée. Configurez-la via Projet -> Paramètres Vibe Godot."
		push_error(msg)
		response_received.emit(msg)
		return response_received
	
	var api_url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" % [model_name, api_key]
	
	var body = {
		"contents": [{"parts": [{"text": prompt_text}]}]
	}
	var headers = ["Content-Type: application/json"]
	var body_json_string = JSON.stringify(body)
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, body_json_string)
	
	if error != OK:
		print("Erreur lors du lancement de la requête HTTP : ", error)
		# On émet un signal d'erreur pour débloquer l'await
		response_received.emit(null)
	
	return response_received


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Erreur de la requête HTTP.")
		response_received.emit(null) # Émettre un signal en cas d'erreur
		return

	if response_code != 200:
		var error_msg = "La requête n'a pas réussi. Code : %d, Réponse : %s" % [response_code, body.get_string_from_utf8()]
		print(error_msg)
		response_received.emit(error_msg) # Émettre un signal en cas d'erreur
		return

	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		print("Erreur de parsing JSON : ", parse_error)
		response_received.emit(null) # Émettre un signal en cas d'erreur
		return

	var response_data = json.get_data()
	if response_data and response_data.has("candidates") and not response_data.candidates.is_empty():
		var generated_text = response_data.candidates[0].content.parts[0].text
		response_received.emit(generated_text)
	else:
		print("Réponse JSON inattendue : ", response_data)
		response_received.emit(null) # Émettre un signal en cas d'erreur
