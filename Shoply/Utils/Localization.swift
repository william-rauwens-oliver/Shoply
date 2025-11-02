//
//  Localization.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Système de localisation simple pour l'application
struct LocalizedString {
    static func localized(_ key: String, for language: AppLanguage? = nil, default defaultValue: String? = nil) -> String {
        let language = language ?? AppSettingsManager.shared.selectedLanguage
        
        // Dictionnaire de traductions
        let translations: [String: [AppLanguage: String]] = [
            // Paramètres
            "Paramètres": [
                .french: "Paramètres",
                .english: "Settings",
                .spanish: "Configuración",
                .german: "Einstellungen",
                .italian: "Impostazioni"
            ],
            "Apparence": [
                .french: "Apparence",
                .english: "Appearance",
                .spanish: "Apariencia",
                .german: "Darstellung",
                .italian: "Aspetto"
            ],
            "Mode sombre": [
                .french: "Mode sombre",
                .english: "Dark mode",
                .spanish: "Modo oscuro",
                .german: "Dunkler Modus",
                .italian: "Modalità scura"
            ],
            "Clair": [
                .french: "Clair",
                .english: "Light",
                .spanish: "Claro",
                .german: "Hell",
                .italian: "Chiaro"
            ],
            "Sombre": [
                .french: "Sombre",
                .english: "Dark",
                .spanish: "Oscuro",
                .german: "Dunkel",
                .italian: "Scuro"
            ],
            "Système": [
                .french: "Système",
                .english: "System",
                .spanish: "Sistema",
                .german: "System",
                .italian: "Sistema"
            ],
            "Langue": [
                .french: "Langue",
                .english: "Language",
                .spanish: "Idioma",
                .german: "Sprache",
                .italian: "Lingua"
            ],
            "Intelligence Artificielle": [
                .french: "Intelligence Artificielle",
                .english: "Artificial Intelligence",
                .spanish: "Inteligencia Artificial",
                .german: "Künstliche Intelligenz",
                .italian: "Intelligenza Artificiale"
            ],
            "Données utilisateur": [
                .french: "Données utilisateur",
                .english: "User Data",
                .spanish: "Datos del usuario",
                .german: "Benutzerdaten",
                .italian: "Dati utente"
            ],
            "Exporter mes données": [
                .french: "Exporter mes données",
                .english: "Export my data",
                .spanish: "Exportar mis datos",
                .german: "Meine Daten exportieren",
                .italian: "Esporta i miei dati"
            ],
            "Télécharger toutes vos données au format JSON": [
                .french: "Télécharger toutes vos données au format JSON",
                .english: "Download all your data in JSON format",
                .spanish: "Descargar todos sus datos en formato JSON",
                .german: "Alle Ihre Daten im JSON-Format herunterladen",
                .italian: "Scarica tutti i tuoi dati in formato JSON"
            ],
            "Supprimer toutes mes données": [
                .french: "Supprimer toutes mes données",
                .english: "Delete all my data",
                .spanish: "Eliminar todos mis datos",
                .german: "Alle meine Daten löschen",
                .italian: "Elimina tutti i miei dati"
            ],
            "Cette action est irréversible": [
                .french: "Cette action est irréversible",
                .english: "This action is irreversible",
                .spanish: "Esta acción es irreversible",
                .german: "Diese Aktion ist irreversibel",
                .italian: "Questa azione è irreversibile"
            ],
            "À propos": [
                .french: "À propos",
                .english: "About",
                .spanish: "Acerca de",
                .german: "Über",
                .italian: "Informazioni"
            ],
            "À propos de Shoply": [
                .french: "À propos de Shoply",
                .english: "About Shoply",
                .spanish: "Acerca de Shoply",
                .german: "Über Shoply",
                .italian: "Informazioni su Shoply"
            ],
            "Version": [
                .french: "Version",
                .english: "Version",
                .spanish: "Versión",
                .german: "Version",
                .italian: "Versione"
            ],
            "Choisir le thème": [
                .french: "Choisir le thème",
                .english: "Choose theme",
                .spanish: "Elegir tema",
                .german: "Design wählen",
                .italian: "Scegli tema"
            ],
            "Sélectionner la langue": [
                .french: "Sélectionner la langue",
                .english: "Select language",
                .spanish: "Seleccionar idioma",
                .german: "Sprache auswählen",
                .italian: "Seleziona lingua"
            ],
            "Annuler": [
                .french: "Annuler",
                .english: "Cancel",
                .spanish: "Cancelar",
                .german: "Abbrechen",
                .italian: "Annulla"
            ],
            "Fermer": [
                .french: "Fermer",
                .english: "Close",
                .spanish: "Cerrar",
                .german: "Schließen",
                .italian: "Chiudi"
            ],
            "Connectez-vous à votre compte OpenAI pour utiliser les suggestions intelligentes d'outfits basées sur vos photos.": [
                .french: "Connectez-vous à votre compte OpenAI pour utiliser les suggestions intelligentes d'outfits basées sur vos photos.",
                .english: "Connect to your OpenAI account to use intelligent outfit suggestions based on your photos.",
                .spanish: "Conéctese a su cuenta de OpenAI para usar sugerencias inteligentes de outfits basadas en sus fotos.",
                .german: "Verbinden Sie sich mit Ihrem OpenAI-Konto, um intelligente Outfit-Vorschläge basierend auf Ihren Fotos zu verwenden.",
                .italian: "Connettiti al tuo account OpenAI per utilizzare suggerimenti intelligenti di outfit basati sulle tue foto."
            ],
            "Connecté à ChatGPT": [
                .french: "Connecté à ChatGPT",
                .english: "Connected to ChatGPT",
                .spanish: "Conectado a ChatGPT",
                .german: "Mit ChatGPT verbunden",
                .italian: "Connesso a ChatGPT"
            ],
            "Déconnecter": [
                .french: "Déconnecter",
                .english: "Disconnect",
                .spanish: "Desconectar",
                .german: "Trennen",
                .italian: "Disconnetti"
            ],
            "Se connecter à ChatGPT": [
                .french: "Se connecter à ChatGPT",
                .english: "Connect to ChatGPT",
                .spanish: "Conectar a ChatGPT",
                .german: "Mit ChatGPT verbinden",
                .italian: "Connetti a ChatGPT"
            ],
            "Comment ça marche ?": [
                .french: "Comment ça marche ?",
                .english: "How does it work?",
                .spanish: "¿Cómo funciona?",
                .german: "Wie funktioniert es?",
                .italian: "Come funziona?"
            ],
            "Information": [
                .french: "Information",
                .english: "Information",
                .spanish: "Información",
                .german: "Information",
                .italian: "Informazioni"
            ],
            "L'utilisation de ChatGPT consomme des crédits de votre compte OpenAI. Les coûts sont généralement très faibles (quelques centimes par utilisation).": [
                .french: "L'utilisation de ChatGPT consomme des crédits de votre compte OpenAI. Les coûts sont généralement très faibles (quelques centimes par utilisation).",
                .english: "Using ChatGPT consumes credits from your OpenAI account. Costs are generally very low (a few cents per use).",
                .spanish: "El uso de ChatGPT consume créditos de su cuenta de OpenAI. Los costos son generalmente muy bajos (unos centavos por uso).",
                .german: "Die Verwendung von ChatGPT verbraucht Guthaben von Ihrem OpenAI-Konto. Die Kosten sind in der Regel sehr gering (ein paar Cent pro Nutzung).",
                .italian: "L'uso di ChatGPT consuma crediti dal tuo account OpenAI. I costi sono generalmente molto bassi (pochi centesimi per utilizzo)."
            ],
            "Exporter les données": [
                .french: "Exporter les données",
                .english: "Export data",
                .spanish: "Exportar datos",
                .german: "Daten exportieren",
                .italian: "Esporta dati"
            ],
            // HomeScreen
            "Shoply": [
                .french: "Shoply",
                .english: "Shoply",
                .spanish: "Shoply",
                .german: "Shoply",
                .italian: "Shoply"
            ],
            "Bonjour": [
                .french: "Bonjour",
                .english: "Hello",
                .spanish: "Hola",
                .german: "Guten Tag",
                .italian: "Ciao"
            ],
            "Bon après-midi": [
                .french: "Bon après-midi",
                .english: "Good afternoon",
                .spanish: "Buenas tardes",
                .german: "Guten Nachmittag",
                .italian: "Buon pomeriggio"
            ],
            "Bonsoir": [
                .french: "Bonsoir",
                .english: "Good evening",
                .spanish: "Buenas noches",
                .german: "Guten Abend",
                .italian: "Buona sera"
            ],
            "Bonne nuit": [
                .french: "Bonne nuit",
                .english: "Good night",
                .spanish: "Buenas noches",
                .german: "Gute Nacht",
                .italian: "Buona notte"
            ],
            "Météo automatique + IA": [
                .french: "Météo automatique + IA",
                .english: "Automatic weather + AI",
                .spanish: "Clima automático + IA",
                .german: "Automatisches Wetter + KI",
                .italian: "Metà automatico + IA"
            ],
            "Détection automatique": [
                .french: "Détection automatique",
                .english: "Automatic detection",
                .spanish: "Detección automática",
                .german: "Automatische Erkennung",
                .italian: "Rilevamento automatico"
            ],
            "Ma Garde-robe": [
                .french: "Ma Garde-robe",
                .english: "My Wardrobe",
                .spanish: "Mi Armario",
                .german: "Mein Kleiderschrank",
                .italian: "Il Mio Guardaroba"
            ],
            "Prenez vos vêtements en photo": [
                .french: "Prenez vos vêtements en photo",
                .english: "Take photos of your clothes",
                .spanish: "Toma fotos de tu ropa",
                .german: "Mache Fotos von deiner Kleidung",
                .italian: "Scatta foto dei tuoi vestiti"
            ],
            "Historique": [
                .french: "Historique",
                .english: "History",
                .spanish: "Historial",
                .german: "Verlauf",
                .italian: "Cronologia"
            ],
            "Outfits déjà portés": [
                .french: "Outfits déjà portés",
                .english: "Outfits already worn",
                .spanish: "Outfits ya usados",
                .german: "Bereits getragene Outfits",
                .italian: "Outfit già indossati"
            ],
            "Voir l'historique complet": [
                .french: "Voir l'historique complet",
                .english: "View full history",
                .spanish: "Ver historial completo",
                .german: "Vollständigen Verlauf anzeigen",
                .italian: "Vedi cronologia completa"
            ],
            "Planifiez vos outfits à l'avance": [
                .french: "Planifiez vos outfits à l'avance",
                .english: "Plan your outfits in advance",
                .spanish: "Planifica tus outfits con anticipación",
                .german: "Planen Sie Ihre Outfits im Voraus",
                .italian: "Pianifica i tuoi outfit in anticipo"
            ],
            // ProfileScreen
            "Profil": [
                .french: "Profil",
                .english: "Profile",
                .spanish: "Perfil",
                .german: "Profil",
                .italian: "Profilo"
            ],
            "Prénom": [
                .french: "Prénom",
                .english: "First name",
                .spanish: "Nombre",
                .german: "Vorname",
                .italian: "Nome"
            ],
            "Votre prénom": [
                .french: "Votre prénom",
                .english: "Your first name",
                .spanish: "Tu nombre",
                .german: "Ihr Vorname",
                .italian: "Il tuo nome"
            ],
            "Âge": [
                .french: "Âge",
                .english: "Age",
                .spanish: "Edad",
                .german: "Alter",
                .italian: "Età"
            ],
            "ans": [
                .french: "ans",
                .english: "years old",
                .spanish: "años",
                .german: "Jahre",
                .italian: "anni"
            ],
            "Genre": [
                .french: "Genre",
                .english: "Gender",
                .spanish: "Género",
                .german: "Geschlecht",
                .italian: "Genere"
            ],
            "Non renseigné": [
                .french: "Non renseigné",
                .english: "Not specified",
                .spanish: "No especificado",
                .german: "Nicht angegeben",
                .italian: "Non specificato"
            ],
            "Modifier": [
                .french: "Modifier",
                .english: "Edit",
                .spanish: "Editar",
                .german: "Bearbeiten",
                .italian: "Modifica"
            ],
            "Enregistrer": [
                .french: "Enregistrer",
                .english: "Save",
                .spanish: "Guardar",
                .german: "Speichern",
                .italian: "Salva"
            ],
            "Le prénom ne peut pas être vide.": [
                .french: "Le prénom ne peut pas être vide.",
                .english: "First name cannot be empty.",
                .spanish: "El nombre no puede estar vacío.",
                .german: "Der Vorname darf nicht leer sein.",
                .italian: "Il nome non può essere vuoto."
            ],
            "Profil mis à jour avec succès.": [
                .french: "Profil mis à jour avec succès.",
                .english: "Profile updated successfully.",
                .spanish: "Perfil actualizado exitosamente.",
                .german: "Profil erfolgreich aktualisiert.",
                .italian: "Profilo aggiornato con successo."
            ],
            // Chat AI
            "Assistant": [
                .french: "Assistant",
                .english: "Assistant",
                .spanish: "Asistente",
                .german: "Assistent",
                .italian: "Assistente"
            ],
            "Assistant Style": [
                .french: "Assistant Style",
                .english: "Style Assistant",
                .spanish: "Asistente de Estilo",
                .german: "Stil-Assistent",
                .italian: "Assistente di Stile"
            ],
            "Conseils de Style": [
                .french: "Conseils de Style",
                .english: "Style Advice",
                .spanish: "Consejos de Estilo",
                .german: "Stilberatung",
                .italian: "Consigli di Stile"
            ],
            "Posez-moi vos questions sur vos outfits, la météo, ou vos vêtements !": [
                .french: "Posez-moi vos questions sur vos outfits, la météo, ou vos vêtements !",
                .english: "Ask me questions about your outfits, weather, or clothes!",
                .spanish: "¡Hazme preguntas sobre tus outfits, el clima o tu ropa!",
                .german: "Stellen Sie mir Fragen zu Ihren Outfits, dem Wetter oder Ihrer Kleidung!",
                .italian: "Fammi domande sui tuoi outfit, il meteo o i tuoi vestiti!"
            ],
            "Posez votre question...": [
                .french: "Posez votre question...",
                .english: "Ask your question...",
                .spanish: "Haz tu pregunta...",
                .german: "Stellen Sie Ihre Frage...",
                .italian: "Fai la tua domanda..."
            ],
            "L'IA réfléchit...": [
                .french: "L'IA réfléchit...",
                .english: "AI is thinking...",
                .spanish: "La IA está pensando...",
                .german: "KI denkt nach...",
                .italian: "L'IA sta pensando..."
            ],
            "Je peux uniquement répondre à des questions concernant vos vêtements, outfits, la météo, le style et la mode. Posez-moi une question sur ces sujets !": [
                .french: "Je peux uniquement répondre à des questions concernant vos vêtements, outfits, la météo, le style et la mode. Posez-moi une question sur ces sujets !",
                .english: "I can only answer questions about your clothes, outfits, weather, style and fashion. Ask me a question about these topics!",
                .spanish: "Solo puedo responder preguntas sobre tu ropa, outfits, clima, estilo y moda. ¡Hazme una pregunta sobre estos temas!",
                .german: "Ich kann nur Fragen zu Ihrer Kleidung, Outfits, Wetter, Stil und Mode beantworten. Stellen Sie mir eine Frage zu diesen Themen!",
                .italian: "Posso rispondere solo a domande sui tuoi vestiti, outfit, meteo, stile e moda. Fammi una domanda su questi argomenti!"
            ],
            "Désolé, une erreur s'est produite. Veuillez réessayer.": [
                .french: "Désolé, une erreur s'est produite. Veuillez réessayer.",
                .english: "Sorry, an error occurred. Please try again.",
                .spanish: "Lo siento, ocurrió un error. Por favor, inténtalo de nuevo.",
                .german: "Entschuldigung, ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.",
                .italian: "Spiacenti, si è verificato un errore. Per favore riprova."
            ],
            "Mode IA": [
                .french: "Mode IA",
                .english: "AI Mode",
                .spanish: "Modo IA",
                .german: "KI-Modus",
                .italian: "Modalità IA"
            ],
            "ChatGPT": [
                .french: "ChatGPT",
                .english: "ChatGPT",
                .spanish: "ChatGPT",
                .german: "ChatGPT",
                .italian: "ChatGPT"
            ],
            "IA Locale": [
                .french: "Shoply AI",
                .english: "Shoply AI",
                .spanish: "Shoply AI",
                .german: "Shoply AI",
                .italian: "Shoply AI"
            ],
            "Désolé, ChatGPT n'est pas disponible. Voulez-vous essayer avec l'IA locale ?": [
                .french: "Désolé, ChatGPT n'est pas disponible. Voulez-vous essayer avec Shoply AI ?",
                .english: "Sorry, ChatGPT is not available. Would you like to try with Shoply AI?",
                .spanish: "Lo siento, ChatGPT no está disponible. ¿Te gustaría probar con Shoply AI?",
                .german: "Entschuldigung, ChatGPT ist nicht verfügbar. Möchten Sie es mit Shoply AI versuchen?",
                .italian: "Spiacenti, ChatGPT non è disponibile. Vuoi provare con Shoply AI?"
            ],
            "Désolé, ChatGPT n'est pas disponible. Essayez de passer en mode IA Locale dans les paramètres en haut.": [
                .french: "Désolé, ChatGPT n'est pas disponible. Essayez de passer en mode Shoply AI dans les paramètres en haut.",
                .english: "Sorry, ChatGPT is not available. Try switching to Shoply AI mode in the settings above.",
                .spanish: "Lo siento, ChatGPT no está disponible. Intenta cambiar al modo Shoply AI en la configuración de arriba.",
                .german: "Entschuldigung, ChatGPT ist nicht verfügbar. Versuchen Sie, in den Einstellungen oben in den Shoply AI-Modus zu wechseln.",
                .italian: "Spiacenti, ChatGPT non è disponibile. Prova a passare alla modalità Shoply AI nelle impostazioni in alto."
            ],
            "Je peux vous aider avec des conseils sur vos vêtements, outfits, la météo, le style et la mode. Posez-moi une question sur ces sujets !": [
                .french: "Je peux vous aider avec des conseils sur vos vêtements, outfits, la météo, le style et la mode. Posez-moi une question sur ces sujets !",
                .english: "I can help you with advice on your clothes, outfits, weather, style and fashion. Ask me a question about these topics!",
                .spanish: "Puedo ayudarte con consejos sobre tu ropa, outfits, clima, estilo y moda. ¡Hazme una pregunta sobre estos temas!",
                .german: "Ich kann Ihnen mit Ratschlägen zu Ihrer Kleidung, Outfits, Wetter, Stil und Mode helfen. Stellen Sie mir eine Frage zu diesen Themen!",
                .italian: "Posso aiutarti con consigli sui tuoi vestiti, outfit, meteo, stile e moda. Fammi una domanda su questi argomenti!"
            ],
            "Salut ! Je suis là pour vous aider avec vos questions sur la mode, les outfits et les vêtements. Que souhaitez-vous savoir ?": [
                .french: "Salut ! Je suis là pour vous aider avec vos questions sur la mode, les outfits et les vêtements. Que souhaitez-vous savoir ?",
                .english: "Hi! I'm here to help you with your questions about fashion, outfits and clothes. What would you like to know?",
                .spanish: "¡Hola! Estoy aquí para ayudarte con tus preguntas sobre moda, outfits y ropa. ¿Qué te gustaría saber?",
                .german: "Hallo! Ich bin hier, um Ihnen bei Ihren Fragen zu Mode, Outfits und Kleidung zu helfen. Was möchten Sie wissen?",
                .italian: "Ciao! Sono qui per aiutarti con le tue domande su moda, outfit e vestiti. Cosa vorresti sapere?"
            ],
            "Conversations": [
                .french: "Conversations",
                .english: "Conversations",
                .spanish: "Conversaciones",
                .german: "Unterhaltungen",
                .italian: "Conversazioni"
            ],
            "Aucune conversation": [
                .french: "Aucune conversation",
                .english: "No conversations",
                .spanish: "Sin conversaciones",
                .german: "Keine Unterhaltungen",
                .italian: "Nessuna conversazione"
            ],
            "Démarrrez une nouvelle conversation pour obtenir des conseils de style !": [
                .french: "Démarrrez une nouvelle conversation pour obtenir des conseils de style !",
                .english: "Start a new conversation to get style advice!",
                .spanish: "¡Inicia una nueva conversación para obtener consejos de estilo!",
                .german: "Starten Sie eine neue Unterhaltung, um Stilberatung zu erhalten!",
                .italian: "Inizia una nuova conversazione per ricevere consigli di stile!"
            ],
            "Nouvelle conversation": [
                .french: "Nouvelle conversation",
                .english: "New conversation",
                .spanish: "Nueva conversación",
                .german: "Neue Unterhaltung",
                .italian: "Nuova conversazione"
            ],
            "Historique des conversations": [
                .french: "Historique",
                .english: "History",
                .spanish: "Historial",
                .german: "Verlauf",
                .italian: "Cronologia"
            ],
            "Fournisseur IA": [
                .french: "Fournisseur IA",
                .english: "AI Provider",
                .spanish: "Proveedor IA",
                .german: "KI-Anbieter",
                .italian: "Fornitore IA"
            ],
            "Google Gemini": [
                .french: "Google Gemini",
                .english: "Google Gemini",
                .spanish: "Google Gemini",
                .german: "Google Gemini",
                .italian: "Google Gemini"
            ],
            "Connectez-vous à Google Gemini pour utiliser les suggestions intelligentes d'outfits basées sur vos photos.": [
                .french: "Connectez-vous à Google Gemini pour utiliser les suggestions intelligentes d'outfits basées sur vos photos.",
                .english: "Connect to Google Gemini to use intelligent outfit suggestions based on your photos.",
                .spanish: "Conéctate a Google Gemini para usar sugerencias inteligentes de outfits basadas en tus fotos.",
                .german: "Verbinden Sie sich mit Google Gemini, um intelligente Outfit-Vorschläge basierend auf Ihren Fotos zu verwenden.",
                .italian: "Connettiti a Google Gemini per utilizzare suggerimenti intelligenti di outfit basati sulle tue foto."
            ],
            "Configurer Gemini": [
                .french: "Configurer Gemini",
                .english: "Configure Gemini",
                .spanish: "Configurar Gemini",
                .german: "Gemini konfigurieren",
                .italian: "Configura Gemini"
            ],
            "Connecté à Gemini": [
                .french: "Connecté à Gemini",
                .english: "Connected to Gemini",
                .spanish: "Conectado a Gemini",
                .german: "Mit Gemini verbunden",
                .italian: "Connesso a Gemini"
            ],
            "Clé API Gemini": [
                .french: "Clé API Gemini",
                .english: "Gemini API Key",
                .spanish: "Clave API Gemini",
                .german: "Gemini API-Schlüssel",
                .italian: "Chiave API Gemini"
            ],
            "Entrez votre clé API Google Gemini": [
                .french: "Entrez votre clé API Google Gemini",
                .english: "Enter your Google Gemini API key",
                .spanish: "Ingresa tu clave API de Google Gemini",
                .german: "Geben Sie Ihren Google Gemini API-Schlüssel ein",
                .italian: "Inserisci la tua chiave API Google Gemini"
            ],
            "Vous pouvez obtenir votre clé API sur : https://makersuite.google.com/app/apikey": [
                .french: "Vous pouvez obtenir votre clé API sur : https://makersuite.google.com/app/apikey",
                .english: "You can get your API key at: https://makersuite.google.com/app/apikey",
                .spanish: "Puedes obtener tu clave API en: https://makersuite.google.com/app/apikey",
                .german: "Sie können Ihren API-Schlüssel unter erhalten: https://makersuite.google.com/app/apikey",
                .italian: "Puoi ottenere la tua chiave API su: https://makersuite.google.com/app/apikey"
            ],
            "Votre clé API Gemini": [
                .french: "Votre clé API Gemini",
                .english: "Your Gemini API key",
                .spanish: "Tu clave API Gemini",
                .german: "Ihr Gemini API-Schlüssel",
                .italian: "La tua chiave API Gemini"
            ],
            "⚠️ Gemini n'est pas disponible. Utilisation de Shoply AI à la place.": [
                .french: "⚠️ Gemini n'est pas disponible. Utilisation de Shoply AI à la place.",
                .english: "⚠️ Gemini is not available. Using Shoply AI instead.",
                .spanish: "⚠️ Gemini no está disponible. Usando Shoply AI en su lugar.",
                .german: "⚠️ Gemini ist nicht verfügbar. Verwenden von Shoply AI stattdessen.",
                .italian: "⚠️ Gemini non è disponibile. Utilizzo di Shoply AI invece."
            ],
            "⚠️ ChatGPT n'est pas disponible. Utilisation de Shoply AI à la place.": [
                .french: "⚠️ ChatGPT n'est pas disponible. Utilisation de Shoply AI à la place.",
                .english: "⚠️ ChatGPT is not available. Using Shoply AI instead.",
                .spanish: "⚠️ ChatGPT no está disponible. Usando Shoply AI en su lugar.",
                .german: "⚠️ ChatGPT ist nicht verfügbar. Verwenden von Shoply AI stattdessen.",
                .italian: "⚠️ ChatGPT non è disponibile. Utilizzo di Shoply AI invece."
            ],
            "⚠️ Aucun service IA avancé disponible. Utilisation de Shoply AI.": [
                .french: "⚠️ Aucun service IA avancé disponible. Utilisation de Shoply AI.",
                .english: "⚠️ No advanced AI service available. Using Shoply AI.",
                .spanish: "⚠️ No hay servicio de IA avanzado disponible. Usando Shoply AI.",
                .german: "⚠️ Kein erweiteter KI-Service verfügbar. Verwenden von Shoply AI.",
                .italian: "⚠️ Nessun servizio IA avanzato disponibile. Utilizzo di Shoply AI."
            ],
            "Se connecter avec OpenAI": [
                .french: "Se connecter avec OpenAI",
                .english: "Sign in with OpenAI",
                .spanish: "Iniciar sesión con OpenAI",
                .german: "Mit OpenAI anmelden",
                .italian: "Accedi con OpenAI"
            ],
            "Se connecter avec Google": [
                .french: "Se connecter avec Google",
                .english: "Sign in with Google",
                .spanish: "Iniciar sesión con Google",
                .german: "Mit Google anmelden",
                .italian: "Accedi con Google"
            ],
            "Utiliser votre compte OpenAI (avec quota)": [
                .french: "Utiliser votre compte OpenAI (avec quota)",
                .english: "Use your OpenAI account (with quota)",
                .spanish: "Usar tu cuenta de OpenAI (con cuota)",
                .german: "Verwenden Sie Ihr OpenAI-Konto (mit Kontingent)",
                .italian: "Usa il tuo account OpenAI (con quota)"
            ],
            "Utiliser votre compte Google (avec quota)": [
                .french: "Utiliser votre compte Google (avec quota)",
                .english: "Use your Google account (with quota)",
                .spanish: "Usar tu cuenta de Google (con cuota)",
                .german: "Verwenden Sie Ihr Google-Konto (mit Kontingent)",
                .italian: "Usa il tuo account Google (con quota)"
            ],
            "OU": [
                .french: "OU",
                .english: "OR",
                .spanish: "O",
                .german: "ODER",
                .italian: "OPPURE"
            ],
            "Utiliser une clé API": [
                .french: "Utiliser une clé API",
                .english: "Use an API key",
                .spanish: "Usar una clave API",
                .german: "API-Schlüssel verwenden",
                .italian: "Usa una chiave API"
            ],
            "Entrer une clé API": [
                .french: "Entrer une clé API",
                .english: "Enter an API key",
                .spanish: "Ingresar una clave API",
                .german: "API-Schlüssel eingeben",
                .italian: "Inserisci una chiave API"
            ],
            "Authentification réussie !": [
                .french: "Authentification réussie !",
                .english: "Authentication successful!",
                .spanish: "¡Autenticación exitosa!",
                .german: "Authentifizierung erfolgreich!",
                .italian: "Autenticazione riuscita!"
            ],
            "Supprimer toutes les conversations": [
                .french: "Supprimer toutes les conversations",
                .english: "Delete all conversations",
                .spanish: "Eliminar todas las conversaciones",
                .german: "Alle Gespräche löschen",
                .italian: "Elimina tutte le conversazioni"
            ],
            "Supprimer toutes les conversations ?": [
                .french: "Supprimer toutes les conversations ?",
                .english: "Delete all conversations?",
                .spanish: "¿Eliminar todas las conversaciones?",
                .german: "Alle Gespräche löschen?",
                .italian: "Eliminare tutte le conversazioni?"
            ],
            "Cette action est irréversible.": [
                .french: "Cette action est irréversible.",
                .english: "This action is irreversible.",
                .spanish: "Esta acción es irreversible.",
                .german: "Diese Aktion ist unwiderruflich.",
                .italian: "Questa azione è irreversibile."
            ],
            "Synchronisation iCloud": [
                .french: "Synchronisation iCloud",
                .english: "iCloud Sync",
                .spanish: "Sincronización iCloud",
                .german: "iCloud-Synchronisation",
                .italian: "Sincronizzazione iCloud"
            ],
            "Sauvegarde iCloud": [
                .french: "Sauvegarde iCloud",
                .english: "iCloud Backup",
                .spanish: "Copia de seguridad iCloud",
                .german: "iCloud-Sicherung",
                .italian: "Backup iCloud"
            ],
            "Vos données sont synchronisées avec iCloud": [
                .french: "Vos données sont synchronisées avec iCloud",
                .english: "Your data is synced with iCloud",
                .spanish: "Tus datos están sincronizados con iCloud",
                .german: "Ihre Daten sind mit iCloud synchronisiert",
                .italian: "I tuoi dati sono sincronizzati con iCloud"
            ],
            "Connectez-vous à iCloud pour sauvegarder vos données": [
                .french: "Connectez-vous à iCloud pour sauvegarder vos données",
                .english: "Sign in to iCloud to backup your data",
                .spanish: "Inicia sesión en iCloud para hacer una copia de seguridad de tus datos",
                .german: "Melden Sie sich bei iCloud an, um Ihre Daten zu sichern",
                .italian: "Accedi a iCloud per eseguire il backup dei tuoi dati"
            ],
            "Synchroniser maintenant": [
                .french: "Synchroniser maintenant",
                .english: "Sync now",
                .spanish: "Sincronizar ahora",
                .german: "Jetzt synchronisieren",
                .italian: "Sincronizza ora"
            ],
            "Récupérer depuis iCloud": [
                .french: "Récupérer depuis iCloud",
                .english: "Restore from iCloud",
                .spanish: "Restaurar desde iCloud",
                .german: "Von iCloud wiederherstellen",
                .italian: "Ripristina da iCloud"
            ],
            "Connectez-vous à iCloud dans Réglages → [Votre nom] → iCloud": [
                .french: "Connectez-vous à iCloud dans Réglages → [Votre nom] → iCloud",
                .english: "Sign in to iCloud in Settings → [Your name] → iCloud",
                .spanish: "Inicia sesión en iCloud en Configuración → [Tu nombre] → iCloud",
                .german: "Melden Sie sich in Einstellungen → [Ihr Name] → iCloud an",
                .italian: "Accedi a iCloud in Impostazioni → [Il tuo nome] → iCloud"
            ],
            "Synchronisation réussie !": [
                .french: "Synchronisation réussie !",
                .english: "Sync successful!",
                .spanish: "¡Sincronización exitosa!",
                .german: "Synchronisation erfolgreich!",
                .italian: "Sincronizzazione riuscita!"
            ],
            "Données restaurées depuis iCloud !": [
                .french: "Données restaurées depuis iCloud !",
                .english: "Data restored from iCloud!",
                .spanish: "¡Datos restaurados desde iCloud!",
                .german: "Daten von iCloud wiederhergestellt!",
                .italian: "Dati ripristinati da iCloud!"
            ],
            "Erreur de synchronisation:": [
                .french: "Erreur de synchronisation:",
                .english: "Sync error:",
                .spanish: "Error de sincronización:",
                .german: "Synchronisationsfehler:",
                .italian: "Errore di sincronizzazione:"
            ],
            "Erreur de restauration:": [
                .french: "Erreur de restauration:",
                .english: "Restore error:",
                .spanish: "Error de restauración:",
                .german: "Wiederherstellungsfehler:",
                .italian: "Errore di ripristino:"
            ],
            "Synchronisation en cours...": [
                .french: "Synchronisation en cours...",
                .english: "Syncing...",
                .spanish: "Sincronizando...",
                .german: "Wird synchronisiert...",
                .italian: "Sincronizzazione in corso..."
            ],
            "Synchronisation terminée": [
                .french: "Synchronisation terminée",
                .english: "Sync completed",
                .spanish: "Sincronización completada",
                .german: "Synchronisation abgeschlossen",
                .italian: "Sincronizzazione completata"
            ],
            "Entrez votre clé API Google Gemini. Vous pouvez l'obtenir sur https://makersuite.google.com/app/apikey": [
                .french: "Entrez votre clé API Google Gemini. Vous pouvez l'obtenir sur https://makersuite.google.com/app/apikey",
                .english: "Enter your Google Gemini API key. You can get it at https://makersuite.google.com/app/apikey",
                .spanish: "Ingresa tu clave API de Google Gemini. Puedes obtenerla en https://makersuite.google.com/app/apikey",
                .german: "Geben Sie Ihren Google Gemini API-Schlüssel ein. Sie können ihn unter https://makersuite.google.com/app/apikey erhalten",
                .italian: "Inserisci la tua chiave API Google Gemini. Puoi ottenerla su https://makersuite.google.com/app/apikey"
            ],
            "Clé API enregistrée avec succès.": [
                .french: "Clé API enregistrée avec succès.",
                .english: "API key saved successfully.",
                .spanish: "Clave API guardada exitosamente.",
                .german: "API-Schlüssel erfolgreich gespeichert.",
                .italian: "Chiave API salvata con successo."
            ],
            "Affiche vos outfits du jour et la météo": [
                .french: "Affiche vos outfits du jour et la météo",
                .english: "Shows your outfits of the day and weather",
                .spanish: "Muestra tus outfits del día y el clima",
                .german: "Zeigt deine Outfits des Tages und das Wetter",
                .italian: "Mostra i tuoi outfit del giorno e il meteo"
            ],
            "Outfit du jour": [
                .french: "Outfit du jour",
                .english: "Outfit of the day",
                .spanish: "Outfit del día",
                .german: "Outfit des Tages",
                .italian: "Outfit del giorno"
            ],
            "Ma garde-robe": [
                .french: "Ma garde-robe",
                .english: "My wardrobe",
                .spanish: "Mi armario",
                .german: "Mein Kleiderschrank",
                .italian: "Il mio guardaroba"
            ],
            "articles": [
                .french: "articles",
                .english: "items",
                .spanish: "artículos",
                .german: "Artikel",
                .italian: "articoli"
            ],
            "Cliquez sur \"Configurer Gemini\"": [
                .french: "Cliquez sur \"Configurer Gemini\"",
                .english: "Click on \"Configure Gemini\"",
                .spanish: "Haz clic en \"Configurar Gemini\"",
                .german: "Klicken Sie auf \"Gemini konfigurieren\"",
                .italian: "Clicca su \"Configura Gemini\""
            ],
            "Obtenez votre clé sur makersuite.google.com/app/apikey": [
                .french: "Obtenez votre clé sur makersuite.google.com/app/apikey",
                .english: "Get your key at makersuite.google.com/app/apikey",
                .spanish: "Obtén tu clave en makersuite.google.com/app/apikey",
                .german: "Holen Sie sich Ihren Schlüssel unter makersuite.google.com/app/apikey",
                .italian: "Ottieni la tua chiave su makersuite.google.com/app/apikey"
            ],
            "La clé sera sauvegardée automatiquement": [
                .french: "La clé sera sauvegardée automatiquement",
                .english: "The key will be saved automatically",
                .spanish: "La clave se guardará automáticamente",
                .german: "Der Schlüssel wird automatisch gespeichert",
                .italian: "La chiave verrà salvata automaticamente"
            ],
            "L'utilisation de Gemini est gratuite jusqu'à un certain quota. Au-delà, des frais peuvent s'appliquer selon votre plan Google.": [
                .french: "L'utilisation de Gemini est gratuite jusqu'à un certain quota. Au-delà, des frais peuvent s'appliquer selon votre plan Google.",
                .english: "Gemini usage is free up to a certain quota. Beyond that, fees may apply depending on your Google plan.",
                .spanish: "El uso de Gemini es gratuito hasta cierto límite. Más allá de eso, pueden aplicarse tarifas según su plan de Google.",
                .german: "Die Nutzung von Gemini ist bis zu einem bestimmten Kontingent kostenlos. Darüber hinaus können je nach Ihrem Google-Plan Gebühren anfallen.",
                .italian: "L'uso di Gemini è gratuito fino a un certo limite. Oltre quello, potrebbero applicarsi tariffe in base al tuo piano Google."
            ],
            // Favoris
            "Favoris": [
                .french: "Favoris",
                .english: "Favorites",
                .spanish: "Favoritos",
                .german: "Favoriten",
                .italian: "Preferiti"
            ],
            "Aucun favori": [
                .french: "Aucun favori",
                .english: "No favorites",
                .spanish: "Sin favoritos",
                .german: "Keine Favoriten",
                .italian: "Nessun preferito"
            ],
            "Ajoutez des outfits de l'historique à vos favoris": [
                .french: "Ajoutez des outfits de l'historique à vos favoris",
                .english: "Add outfits from history to your favorites",
                .spanish: "Agrega outfits del historial a tus favoritos",
                .german: "Fügen Sie Outfits aus dem Verlauf zu Ihren Favoriten hinzu",
                .italian: "Aggiungi outfit dalla cronologia ai tuoi preferiti"
            ],
            "Porté le": [
                .french: "Porté le",
                .english: "Worn on",
                .spanish: "Usado el",
                .german: "Getragen am",
                .italian: "Indossato il"
            ],
            // Outfit Selection
            "Outfits pour": [
                .french: "Outfits pour",
                .english: "Outfits for",
                .spanish: "Outfits para",
                .german: "Outfits für",
                .italian: "Outfit per"
            ],
            "Choisissez votre style": [
                .french: "Choisissez votre style",
                .english: "Choose your style",
                .spanish: "Elige tu estilo",
                .german: "Wählen Sie Ihren Stil",
                .italian: "Scegli il tuo stile"
            ],
            "Aucun outfit disponible": [
                .french: "Aucun outfit disponible",
                .english: "No outfit available",
                .spanish: "No hay outfit disponible",
                .german: "Kein Outfit verfügbar",
                .italian: "Nessun outfit disponibile"
            ],
            "outfit trouvé": [
                .french: "outfit trouvé",
                .english: "outfit found",
                .spanish: "outfit encontrado",
                .german: "Outfit gefunden",
                .italian: "outfit trovato"
            ],
            "outfits trouvés": [
                .french: "outfits trouvés",
                .english: "outfits found",
                .spanish: "outfits encontrados",
                .german: "Outfits gefunden",
                .italian: "outfit trovati"
            ],
            "Essayez une autre combinaison d'humeur et de météo": [
                .french: "Essayez une autre combinaison d'humeur et de météo",
                .english: "Try another combination of mood and weather",
                .spanish: "Prueba otra combinación de estado de ánimo y clima",
                .german: "Versuchen Sie eine andere Kombination aus Stimmung und Wetter",
                .italian: "Prova un'altra combinazione di umore e meteo"
            ],
            // Outfit Detail
            "À propos de cet outfit": [
                .french: "À propos de cet outfit",
                .english: "About this outfit",
                .spanish: "Acerca de este outfit",
                .german: "Über dieses Outfit",
                .italian: "Informazioni su questo outfit"
            ],
            "Composition": [
                .french: "Composition",
                .english: "Composition",
                .spanish: "Composición",
                .german: "Zusammensetzung",
                .italian: "Composizione"
            ],
            "Haut": [
                .french: "Haut",
                .english: "Top",
                .spanish: "Parte superior",
                .german: "Oberteil",
                .italian: "Parte superiore"
            ],
            "Bas": [
                .french: "Bas",
                .english: "Bottom",
                .spanish: "Parte inferior",
                .german: "Unterteil",
                .italian: "Parte inferiore"
            ],
            "Chaussures": [
                .french: "Chaussures",
                .english: "Shoes",
                .spanish: "Zapatos",
                .german: "Schuhe",
                .italian: "Scarpe"
            ],
            "Accessoires": [
                .french: "Accessoires",
                .english: "Accessories",
                .spanish: "Accesorios",
                .german: "Accessoires",
                .italian: "Accessori"
            ],
            "Caractéristiques": [
                .french: "Caractéristiques",
                .english: "Characteristics",
                .spanish: "Características",
                .german: "Eigenschaften",
                .italian: "Caratteristiche"
            ],
            // Tutorial
            "Bienvenue dans Shoply !": [
                .french: "Bienvenue dans Shoply !",
                .english: "Welcome to Shoply!",
                .spanish: "¡Bienvenido a Shoply!",
                .german: "Willkommen bei Shoply!",
                .italian: "Benvenuto in Shoply!"
            ],
            "Votre assistant personnel pour créer des outfits parfaits adaptés à la météo et à votre style.": [
                .french: "Votre assistant personnel pour créer des outfits parfaits adaptés à la météo et à votre style.",
                .english: "Your personal assistant to create perfect outfits adapted to the weather and your style.",
                .spanish: "Tu asistente personal para crear outfits perfectos adaptados al clima y a tu estilo.",
                .german: "Ihr persönlicher Assistent zur Erstellung perfekter Outfits, angepasst an das Wetter und Ihren Stil.",
                .italian: "Il tuo assistente personale per creare outfit perfetti adattati al meteo e al tuo stile."
            ],
            "Ajoutez vos vêtements": [
                .french: "Ajoutez vos vêtements",
                .english: "Add your clothes",
                .spanish: "Agrega tu ropa",
                .german: "Fügen Sie Ihre Kleidung hinzu",
                .italian: "Aggiungi i tuoi vestiti"
            ],
            "Commencez par ajouter au moins 5 vêtements dans votre garde-robe avec leurs photos pour que l'IA puisse vous proposer les meilleurs outfits.": [
                .french: "Commencez par ajouter au moins 5 vêtements dans votre garde-robe avec leurs photos pour que l'IA puisse vous proposer les meilleurs outfits.",
                .english: "Start by adding at least 5 clothes to your wardrobe with their photos so the AI can suggest the best outfits.",
                .spanish: "Comienza agregando al menos 5 prendas a tu guardarropa con sus fotos para que la IA pueda sugerirte los mejores outfits.",
                .german: "Beginnen Sie mit dem Hinzufügen von mindestens 5 Kleidungsstücken zu Ihrer Garderobe mit Fotos, damit die KI die besten Outfits vorschlagen kann.",
                .italian: "Inizia aggiungendo almeno 5 vestiti al tuo guardaroba con le loro foto in modo che l'IA possa suggerirti i migliori outfit."
            ],
            "Sélection Intelligente": [
                .french: "Sélection Intelligente",
                .english: "Smart Selection",
                .spanish: "Selección Inteligente",
                .german: "Intelligente Auswahl",
                .italian: "Selezione Intelligente"
            ],
            "Générez des outfits personnalisés en utilisant ChatGPT pour une analyse avancée de vos vêtements, ou utilisez l'algorithme local pour préserver votre confidentialité.": [
                .french: "Générez des outfits personnalisés en utilisant ChatGPT pour une analyse avancée de vos vêtements, ou utilisez l'algorithme local pour préserver votre confidentialité.",
                .english: "Generate personalized outfits using ChatGPT for advanced analysis of your clothes, or use the local algorithm to preserve your privacy.",
                .spanish: "Genera outfits personalizados usando ChatGPT para un análisis avanzado de tu ropa, o usa el algoritmo local para preservar tu privacidad.",
                .german: "Generieren Sie personalisierte Outfits mit ChatGPT zur fortgeschrittenen Analyse Ihrer Kleidung oder verwenden Sie den lokalen Algorithmus, um Ihre Privatsphäre zu wahren.",
                .italian: "Genera outfit personalizzati usando ChatGPT per un'analisi avanzata dei tuoi vestiti, o usa l'algoritmo locale per preservare la tua privacy."
            ],
            "Planifiez vos outfits": [
                .french: "Planifiez vos outfits",
                .english: "Plan your outfits",
                .spanish: "Planea tus outfits",
                .german: "Planen Sie Ihre Outfits",
                .italian: "Pianifica i tuoi outfit"
            ],
            "Consultez le calendrier pour planifier vos tenues à l'avance selon la météo prévue. L'IA s'adapte automatiquement aux conditions.": [
                .french: "Consultez le calendrier pour planifier vos tenues à l'avance selon la météo prévue. L'IA s'adapte automatiquement aux conditions.",
                .english: "Check the calendar to plan your outfits in advance according to the forecasted weather. The AI automatically adapts to conditions.",
                .spanish: "Consulta el calendario para planificar tus outfits con anticipación según el clima previsto. La IA se adapta automáticamente a las condiciones.",
                .german: "Prüfen Sie den Kalender, um Ihre Outfits im Voraus nach der vorhergesagten Wettervorhersage zu planen. Die KI passt sich automatisch an die Bedingungen an.",
                .italian: "Controlla il calendario per pianificare i tuoi outfit in anticipo secondo il meteo previsto. L'IA si adatta automaticamente alle condizioni."
            ],
            "Suivez votre historique": [
                .french: "Suivez votre historique",
                .english: "Track your history",
                .spanish: "Rastrea tu historial",
                .german: "Verfolgen Sie Ihren Verlauf",
                .italian: "Traccia la tua cronologia"
            ],
            "Gardez une trace de vos outfits portés et marquez vos favoris pour retrouver facilement vos combinaisons préférées.": [
                .french: "Gardez une trace de vos outfits portés et marquez vos favoris pour retrouver facilement vos combinaisons préférées.",
                .english: "Keep track of your worn outfits and mark your favorites to easily find your favorite combinations.",
                .spanish: "Mantén un registro de tus outfits usados y marca tus favoritos para encontrar fácilmente tus combinaciones favoritas.",
                .german: "Behalten Sie den Überblick über Ihre getragenen Outfits und markieren Sie Ihre Favoriten, um Ihre Lieblingskombinationen leicht zu finden.",
                .italian: "Tieni traccia dei tuoi outfit indossati e segna i tuoi preferiti per trovare facilmente le tue combinazioni preferite."
            ],
            "Passer": [
                .french: "Passer",
                .english: "Skip",
                .spanish: "Saltar",
                .german: "Überspringen",
                .italian: "Salta"
            ],
            "Précédent": [
                .french: "Précédent",
                .english: "Previous",
                .spanish: "Anterior",
                .german: "Zurück",
                .italian: "Precedente"
            ],
            "Suivant": [
                .french: "Suivant",
                .english: "Next",
                .spanish: "Siguiente",
                .german: "Weiter",
                .italian: "Successivo"
            ],
            "Commencer": [
                .french: "Commencer",
                .english: "Start",
                .spanish: "Comenzar",
                .german: "Beginnen",
                .italian: "Inizia"
            ],
            // Calendrier
            "Calendrier": [
                .french: "Calendrier",
                .english: "Calendar",
                .spanish: "Calendario",
                .german: "Kalender",
                .italian: "Calendario"
            ],
            "Récupérer la météo pour cette date": [
                .french: "Récupérer la météo pour cette date",
                .english: "Get weather for this date",
                .spanish: "Obtener el clima para esta fecha",
                .german: "Wetter für dieses Datum abrufen",
                .italian: "Ottieni il meteo per questa data"
            ],
            "Générer l'outfit pour cette date": [
                .french: "Générer l'outfit pour cette date",
                .english: "Generate outfit for this date",
                .spanish: "Generar outfit para esta fecha",
                .german: "Outfit für dieses Datum generieren",
                .italian: "Genera outfit per questa data"
            ],
            "Outfit pour le": [
                .french: "Outfit pour le",
                .english: "Outfit for",
                .spanish: "Outfit para el",
                .german: "Outfit für den",
                .italian: "Outfit per il"
            ],
            "J'ai porté cet outfit": [
                .french: "J'ai porté cet outfit",
                .english: "I wore this outfit",
                .spanish: "Usé este outfit",
                .german: "Ich habe dieses Outfit getragen",
                .italian: "Ho indossato questo outfit"
            ],
            // Sélection intelligente
            "Sélection intelligente": [
                .french: "Sélection intelligente",
                .english: "Smart selection",
                .spanish: "Selección inteligente",
                .german: "Intelligente Auswahl",
                .italian: "Selezione intelligente"
            ],
            "Laissez l'IA choisir vos meilleurs outfits": [
                .french: "Laissez l'IA choisir vos meilleurs outfits",
                .english: "Let AI choose your best outfits",
                .spanish: "Deja que la IA elija tus mejores outfits",
                .german: "Lassen Sie die KI Ihre besten Outfits auswählen",
                .italian: "Lascia che l'IA scelga i tuoi migliori outfit"
            ],
            "Générer mes outfits": [
                .french: "Générer mes outfits",
                .english: "Generate my outfits",
                .spanish: "Generar mis outfits",
                .german: "Meine Outfits generieren",
                .italian: "Genera i miei outfit"
            ],
            "Méthode de génération": [
                .french: "Méthode de génération",
                .english: "Generation method",
                .spanish: "Método de generación",
                .german: "Generierungsmethode",
                .italian: "Metodo di generazione"
            ],
            "Choisissez comment générer vos outfits": [
                .french: "Choisissez comment générer vos outfits",
                .english: "Choose how to generate your outfits",
                .spanish: "Elige cómo generar tus outfits",
                .german: "Wählen Sie, wie Sie Ihre Outfits generieren möchten",
                .italian: "Scegli come generare i tuoi outfit"
            ],
            "(IA avancée)": [
                .french: "(IA avancée)",
                .english: "(Advanced AI)",
                .spanish: "(IA avanzada)",
                .german: "(Fortgeschrittene KI)",
                .italian: "(IA avanzata)"
            ],
            "Plus puissant • Plus de chances de trouver • Données envoyées à": [
                .french: "Plus puissant • Plus de chances de trouver • Données envoyées à",
                .english: "More powerful • More chances to find • Data sent to",
                .spanish: "Más poderoso • Más posibilidades de encontrar • Datos enviados a",
                .german: "Leistungsstärker • Mehr Chancen zu finden • Daten gesendet an",
                .italian: "Più potente • Più possibilità di trovare • Dati inviati a"
            ],
            "Mon algorithme (local)": [
                .french: "Shoply AI",
                .english: "Shoply AI",
                .spanish: "Shoply AI",
                .german: "Shoply AI",
                .italian: "Shoply AI"
            ],
            "Moins puissant • Données restent sur votre appareil": [
                .french: "Moins puissant • Données restent sur votre appareil",
                .english: "Less powerful • Data stays on your device",
                .spanish: "Menos poderoso • Los datos permanecen en tu dispositivo",
                .german: "Weniger leistungsstark • Daten bleiben auf Ihrem Gerät",
                .italian: "Meno potente • I dati rimangono sul tuo dispositivo"
            ],
            "n'est pas configuré. Utilisation de l'algorithme local.": [
                .french: "n'est pas configuré. Utilisation de l'algorithme local.",
                .english: "is not configured. Using local algorithm.",
                .spanish: "no está configurado. Usando algoritmo local.",
                .german: "ist nicht konfiguriert. Lokaler Algorithmus wird verwendet.",
                .italian: "non è configurato. Uso dell'algoritmo locale."
            ],
            "outfits générés": [
                .french: "outfits générés",
                .english: "outfits generated",
                .spanish: "outfits generados",
                .german: "Outfits generiert",
                .italian: "outfit generati"
            ],
            "Sélectionnés pour vous": [
                .french: "Sélectionnés pour vous",
                .english: "Selected for you",
                .spanish: "Seleccionados para ti",
                .german: "Für Sie ausgewählt",
                .italian: "Selezionati per te"
            ],
            "a sélectionné ces vêtements pour vous": [
                .french: "a sélectionné ces vêtements pour vous",
                .english: "selected these clothes for you",
                .spanish: "seleccionó esta ropa para ti",
                .german: "hat diese Kleidung für Sie ausgewählt",
                .italian: "ha selezionato questi vestiti per te"
            ],
            "Vêtements sélectionnés par": [
                .french: "Vêtements sélectionnés par",
                .english: "Clothes selected by",
                .spanish: "Ropa seleccionada por",
                .german: "Kleidung ausgewählt von",
                .italian: "Vestiti selezionati da"
            ],
            "Retour": [
                .french: "Retour",
                .english: "Back",
                .spanish: "Volver",
                .german: "Zurück",
                .italian: "Indietro"
            ],
            "Préparation de vos vêtements...": [
                .french: "Préparation de vos vêtements...",
                .english: "Preparing your clothes...",
                .spanish: "Preparando tu ropa...",
                .german: "Vorbereitung Ihrer Kleidung...",
                .italian: "Preparazione dei tuoi vestiti..."
            ],
            "Chargement de": [
                .french: "Chargement de",
                .english: "Loading",
                .spanish: "Cargando",
                .german: "Laden von",
                .italian: "Caricamento di"
            ],
            "article(s)...": [
                .french: "article(s)...",
                .english: "item(s)...",
                .spanish: "artículo(s)...",
                .german: "Artikel...",
                .italian: "articolo(i)..."
            ],
            "Envoi des photos à": [
                .french: "Envoi des photos à",
                .english: "Sending photos to",
                .spanish: "Enviando fotos a",
                .german: "Senden von Fotos an",
                .italian: "Invio foto a"
            ],
            "...": [
                .french: "...",
                .english: "...",
                .spanish: "...",
                .german: "...",
                .italian: "..."
            ],
            "réfléchit...": [
                .french: "réfléchit...",
                .english: "is thinking...",
                .spanish: "está pensando...",
                .german: "denkt nach...",
                .italian: "sta pensando..."
            ],
            "sélectionne vos vêtements...": [
                .french: "sélectionne vos vêtements...",
                .english: "is selecting your clothes...",
                .spanish: "está seleccionando tu ropa...",
                .german: "wählt Ihre Kleidung aus...",
                .italian: "sta selezionando i tuoi vestiti..."
            ],
            "Création des meilleurs outfits...": [
                .french: "Création des meilleurs outfits...",
                .english: "Creating the best outfits...",
                .spanish: "Creando los mejores outfits...",
                .german: "Erstellen der besten Outfits...",
                .italian: "Creazione dei migliori outfit..."
            ],
            "Finalisation...": [
                .french: "Finalisation...",
                .english: "Finalizing...",
                .spanish: "Finalizando...",
                .german: "Abschließen...",
                .italian: "Finalizzazione..."
            ],
            "Analyse des couleurs, matières et styles...": [
                .french: "Analyse des couleurs, matières et styles...",
                .english: "Analyzing colors, materials and styles...",
                .spanish: "Analizando colores, materiales y estilos...",
                .german: "Analysieren von Farben, Materialien und Stilen...",
                .italian: "Analisi di colori, materiali e stili..."
            ],
            "Analyse de votre garde-robe...": [
                .french: "Analyse de votre garde-robe...",
                .english: "Analyzing your wardrobe...",
                .spanish: "Analizando tu guardarropa...",
                .german: "Analysieren Ihrer Garderobe...",
                .italian: "Analisi del tuo guardaroba..."
            ],
            "Articles insuffisants": [
                .french: "Articles insuffisants",
                .english: "Insufficient items",
                .spanish: "Artículos insuficientes",
                .german: "Unzureichende Artikel",
                .italian: "Articoli insufficienti"
            ],
            "Vous devez avoir au moins 2 articles dans votre garde-robe avec leurs photos pour générer des outfits. Ajoutez des vêtements depuis la section \"Ma Garde-robe\".": [
                .french: "Vous devez avoir au moins 2 articles dans votre garde-robe avec leurs photos pour générer des outfits. Ajoutez des vêtements depuis la section \"Ma Garde-robe\".",
                .english: "You must have at least 2 items in your wardrobe with their photos to generate outfits. Add clothes from the \"My Wardrobe\" section.",
                .spanish: "Debes tener al menos 2 artículos en tu guardarropa con sus fotos para generar outfits. Agrega ropa desde la sección \"Mi Guardarropa\".",
                .german: "Sie müssen mindestens 2 Artikel in Ihrer Garderobe mit Fotos haben, um Outfits zu generieren. Fügen Sie Kleidung aus dem Abschnitt \"Meine Garderobe\" hinzu.",
                .italian: "Devi avere almeno 2 articoli nel tuo guardaroba con le loro foto per generare outfit. Aggiungi vestiti dalla sezione \"Il Mio Guardaroba\"."
            ],
            "Vous devez avoir au moins 2 articles dans votre garde-robe pour générer des outfits.": [
                .french: "Vous devez avoir au moins 2 articles dans votre garde-robe pour générer des outfits.",
                .english: "You must have at least 2 items in your wardrobe to generate outfits.",
                .spanish: "Debes tener al menos 2 artículos en tu guardarropa para generar outfits.",
                .german: "Sie müssen mindestens 2 Artikel in Ihrer Garderobe haben, um Outfits zu generieren.",
                .italian: "Devi avere almeno 2 articoli nel tuo guardaroba per generare outfit."
            ],
            "Aucun outfit trouvé. Assurez-vous d'avoir au moins un haut et un bas dans votre garde-robe.": [
                .french: "Aucun outfit trouvé. Assurez-vous d'avoir au moins un haut et un bas dans votre garde-robe.",
                .english: "No outfit found. Make sure you have at least a top and a bottom in your wardrobe.",
                .spanish: "No se encontró ningún outfit. Asegúrate de tener al menos una parte superior y una inferior en tu guardarropa.",
                .german: "Kein Outfit gefunden. Stellen Sie sicher, dass Sie mindestens ein Oberteil und ein Unterteil in Ihrer Garderobe haben.",
                .italian: "Nessun outfit trovato. Assicurati di avere almeno una parte superiore e una inferiore nel tuo guardaroba."
            ],
            "Impossible de récupérer la météo. Vérifiez votre connexion et la localisation.": [
                .french: "Impossible de récupérer la météo. Vérifiez votre connexion et la localisation.",
                .english: "Unable to retrieve weather. Check your connection and location.",
                .spanish: "No se puede recuperar el clima. Verifica tu conexión y ubicación.",
                .german: "Wetter kann nicht abgerufen werden. Überprüfen Sie Ihre Verbindung und Ihren Standort.",
                .italian: "Impossibile recuperare il meteo. Verifica la connessione e la posizione."
            ],
            "Veuillez d'abord récupérer la météo pour cette date.": [
                .french: "Veuillez d'abord récupérer la météo pour cette date.",
                .english: "Please first get the weather for this date.",
                .spanish: "Por favor, primero obtén el clima para esta fecha.",
                .german: "Bitte holen Sie zuerst das Wetter für dieses Datum ab.",
                .italian: "Per favore, ottieni prima il meteo per questa data."
            ],
            "Profil utilisateur non trouvé.": [
                .french: "Profil utilisateur non trouvé.",
                .english: "User profile not found.",
                .spanish: "Perfil de usuario no encontrado.",
                .german: "Benutzerprofil nicht gefunden.",
                .italian: "Profilo utente non trovato."
            ],
            "Ajouté à l'historique": [
                .french: "Ajouté à l'historique",
                .english: "Added to history",
                .spanish: "Agregado al historial",
                .german: "Zu Verlauf hinzugefügt",
                .italian: "Aggiunto alla cronologia"
            ],
            // Wardrobe Management
            "Rechercher...": [
                .french: "Rechercher...",
                .english: "Search...",
                .spanish: "Buscar...",
                .german: "Suchen...",
                .italian: "Cerca..."
            ],
            "Aucun {category} dans votre garde-robe": [
                .french: "Aucun {category} dans votre garde-robe",
                .english: "No {category} in your wardrobe",
                .spanish: "No hay {category} en tu armario",
                .german: "Kein {category} in Ihrer Garderobe",
                .italian: "Nessun {category} nel tuo guardaroba"
            ],
            "Appuyez sur + pour ajouter vos premiers vêtements": [
                .french: "Appuyez sur + pour ajouter vos premiers vêtements",
                .english: "Press + to add your first clothes",
                .spanish: "Presiona + para agregar tu primera ropa",
                .german: "Drücken Sie +, um Ihre erste Kleidung hinzuzufügen",
                .italian: "Premi + per aggiungere i tuoi primi vestiti"
            ],
            "Nom": [
                .french: "Nom",
                .english: "Name",
                .spanish: "Nombre",
                .german: "Name",
                .italian: "Nome"
            ],
            "Catégorie": [
                .french: "Catégorie",
                .english: "Category",
                .spanish: "Categoría",
                .german: "Kategorie",
                .italian: "Categoria"
            ],
            "Couleur": [
                .french: "Couleur",
                .english: "Color",
                .spanish: "Color",
                .german: "Farbe",
                .italian: "Colore"
            ],
            "Marque": [
                .french: "Marque",
                .english: "Brand",
                .spanish: "Marca",
                .german: "Marke",
                .italian: "Marca"
            ],
            "Matière": [
                .french: "Matière",
                .english: "Material",
                .spanish: "Material",
                .german: "Material",
                .italian: "Materiale"
            ],
            "Saisons": [
                .french: "Saisons",
                .english: "Seasons",
                .spanish: "Estaciones",
                .german: "Jahreszeiten",
                .italian: "Stagioni"
            ],
            "Supprimer": [
                .french: "Supprimer",
                .english: "Delete",
                .spanish: "Eliminar",
                .german: "Löschen",
                .italian: "Elimina"
            ],
            "Êtes-vous sûr de vouloir supprimer cet article de votre garde-robe ?": [
                .french: "Êtes-vous sûr de vouloir supprimer cet article de votre garde-robe ?",
                .english: "Are you sure you want to delete this item from your wardrobe?",
                .spanish: "¿Estás seguro de que quieres eliminar este artículo de tu armario?",
                .german: "Sind Sie sicher, dass Sie diesen Artikel aus Ihrer Garderobe löschen möchten?",
                .italian: "Sei sicuro di voler eliminare questo articolo dal tuo guardaroba?"
            ]
        ]
        
        // Récupérer la traduction pour la langue sélectionnée
        if let translationsForKey = translations[key] {
            // Essayer la langue sélectionnée
            if let translation = translationsForKey[language] {
                return translation
            }
            
            // Fallback: essayer les langues de base dans l'ordre de priorité
            let fallbackLanguages: [AppLanguage] = [.english, .french, .spanish, .german, .italian]
            for fallbackLang in fallbackLanguages {
                if let translation = translationsForKey[fallbackLang] {
                    return translation
                }
            }
        }
        
        // Si pas de traduction, retourner la valeur par défaut ou la clé
        return defaultValue ?? key
    }
}

// Extension pour faciliter l'utilisation
extension String {
    var localized: String {
        return LocalizedString.localized(self, for: AppSettingsManager.shared.selectedLanguage)
    }
}

