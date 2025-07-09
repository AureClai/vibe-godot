<p align="center">
  <img src="URL_DE_VOTRE_LOGO_ICI" width="200" alt="Vibe Godot Logo">
</p>

<h1 align="center">Vibe Godot ✨</h1>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0-blue.svg"/>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green.svg"/>
  <img alt="Godot Version" src="https://img.shields.io/badge/Godot-4.2%2B-%23478cbf"/>
</p>

<p align="center">
  <i>Vibe coding for Godot 4, powered by Google Gemini.</i>
</p>

**Vibe Godot** is a plugin for the Godot Engine that brings the power of the Gemini AI directly into your editor. Stop switching contexts and stay in the flow. Generate code, refactor scripts, and get ideas without ever leaving Godot.

---

### ## 🎯 Features

* **Generate GDScript:** Describe a function, get the code.
* **Refactor Existing Code:** Ask for modifications to your scripts using the `@script.gd` syntax.
* **Integrated UI:** A simple dock UI to interact with the AI.
* **Custom Settings:** Configure your API key and model choice via a dedicated project menu.

---

### ## 🚀 Installation

1.  **Download:** Go to the [Releases page](https://github.com/your-username/your-repo/releases) of your repository and download the latest `vibe-godot.zip` file.
2.  **Extract:** Unzip the file. It will contain an `addons` folder.
3.  **Copy:** Copy the `addons` folder into the root of your Godot project. Your project structure should look like `res://addons/vibe_godot/`.
4.  **Configure Autoload (Étape Cruciale !):**
	* In Godot, go to `Projet > Paramètres du projet...`.
	* Go to the `Autoload` tab.
	* For the `Chemin`, click the folder icon and select `res://addons/vibe_godot/api/GeminiAPI.gd`.
	* In the `Nom du Nœud` field, type **`GeminiAPI`**.
	* Click **"Ajouter"**.
5.  **Activate Plugin:**
	* Go to the `Plugins` tab in the Project Settings.
	* Find "Vibe Godot" and set its status to **Actif**.

---

### ## ⚙️ Configuration

Before using the plugin, you **must** configure your Google Gemini API key.

1.  In the Godot editor, go to the top menu: `Projet > Paramètres Vibe Godot`.
2.  A window will appear. Paste your API key into the "Clé API Gemini" field.
3.  (Optional) Change the Gemini model name if needed.
4.  Click "Enregistrer et Fermer".

---

### ## 🎮 How to Use

Once activated, you will see a new "Vibe Godot" dock on the right side of the editor.

#### Generate New Code
Simply describe what you want.
> **Prompt:** `une fonction qui fait sauter un CharacterBody2D avec la touche espace`

#### Refactor a Script
Use the `@` syntax to reference a script from your project. The script must be saved in your project filesystem (`res://...`).
> **Prompt:** `refactorise ce script pour utiliser une state machine @player.gd`

---

### ## 📄 License
This plugin is distributed under the MIT License. See `LICENSE` for more information.

### ## ❤️ Contributing
Found a bug or have a feature request? Feel free to open an issue on the [GitHub repository Issues page](https://github.com/your-username/your-repo/issues).
