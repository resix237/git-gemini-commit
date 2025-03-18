#!/bin/bash

# Fonction d'affichage des messages d'erreur
error_exit() {
    echo "ERREUR: $1" >&2
    exit 1
}

# Vérifier si les dépendances sont installées
check_dependencies() {
    for cmd in git curl jq; do
        if ! command -v $cmd &> /dev/null; then
            error_exit "La commande '$cmd' est requise mais n'est pas installée. Installez-la avec 'sudo apt install $cmd'."
        fi
    done
}

# Fonction pour lire la clé API depuis la configuration
get_api_key() {
    api_key=$(git config --get gemini.apikey)
    
    if [ -z "$api_key" ]; then
        echo "Aucune clé API Gemini n'a été configurée."
        echo "Utilisez 'git config --global gemini.apikey VOTRE_CLE_API' pour configurer votre clé API."
        exit 1
    fi
    
    echo "$api_key"
}

# Fonction pour éditer du texte avec l'éditeur par défaut
edit_text() {
    local content="$1"
    local temp_file=$(mktemp)
    
    # Écrire le contenu dans un fichier temporaire
    echo "$content" > "$temp_file"
    
    # Ouvrir l'éditeur
    ${EDITOR:-vim} "$temp_file"
    
    # Lire le contenu modifié
    local edited_content=$(cat "$temp_file")
    
    # Supprimer le fichier temporaire
    rm "$temp_file"
    
    echo "$edited_content"
}

# Fonction pour nettoyer le texte des backticks
clean_response() {
    local text="$1"
    # Supprimer les backticks triples et tout formatage markdown potentiel
    echo "$text" | sed 's/```[a-zA-Z]*//g' | sed 's/```//g'
}

# Fonction principale
main() {
    # Vérifier les dépendances
    check_dependencies
    
    # Vérifier si le répertoire est un dépôt Git
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        error_exit "Ce n'est pas un dépôt Git."
    fi
    
    # Récupérer les modifications
    git_diff=$(git diff --staged --stat)
    diff_content=$(git diff --staged)
    
    # Vérifier s'il y a des modifications
    if [ -z "$git_diff" ]; then
        error_exit "Aucune modification n'a été ajoutée à l'index. Utilisez 'git add' pour ajouter des fichiers."
    fi
    
    # Afficher les modifications
    echo "Modifications détectées :"
    echo "$git_diff"
    echo "-----------------------------------------"
    
    # Récupérer la clé API
    api_key=$(get_api_key)
    
    # Formater le prompt pour éviter les problèmes avec les caractères spéciaux
    prompt_text="Génère un message de commit concis et descriptif pour les modifications suivantes dans mon dépôt Git : $git_diff. Détails des modifications : $diff_content. Assure-toi que la première ligne est un titre court et concis, puis ajoute une ligne vide suivie d'une description plus détaillée. N'utilise pas de formatage markdown ni de symboles backticks."
    
    # Échapper les caractères spéciaux pour JSON
    prompt_json=$(echo "$prompt_text" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\t/\\t/g')
    
    echo "Consultation de l'API Gemini pour générer un message de commit..."
    
    # Appeler l'API Gemini
    response=$(curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$api_key" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{
        \"contents\": [{
        \"parts\": [{
            \"text\": \"$prompt_json\"
        }]
        }]
    }")
    
    # Extraire le message de commit suggéré en utilisant jq
    if command -v jq &> /dev/null; then
        commit_message=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)
    else
        # Sinon, utiliser Python si disponible
        if command -v python3 &> /dev/null; then
            commit_message=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['candidates'][0]['content']['parts'][0]['text'])" 2>/dev/null)
        else
            # Solution de secours avec grep et sed (moins fiable)
            commit_message=$(echo "$response" | grep -o '"parts":\[{"text":"[^"]*"' | sed 's/"parts":\[{"text":"//g' | sed 's/"//g')
        fi
    fi

    # Nettoyer le message des backticks potentiels
    commit_message=$(clean_response "$commit_message")

    # Extraire le titre et la description
    commit_title=$(echo "$commit_message" | head -n 1)
    commit_description=$(echo "$commit_message" | tail -n +2)
    
    echo "Message de commit généré :"
    echo "-----------------------------------------"
    echo "$commit_message"
    echo "-----------------------------------------"
    
    # Demander à l'utilisateur ce qu'il souhaite faire
    echo "Options:"
    echo "1. Utiliser ce message tel quel"
    echo "2. Modifier le message avant de l'utiliser"
    echo "3. Modifier seulement le titre"
    echo "4. Modifier seulement la description"
    echo "5. Annuler et faire un commit manuel"
    read -p "Votre choix (1-5): " choice
    
    case $choice in
        1)
            # Utiliser tel quel
            git commit -m "$commit_title" -m "$commit_description"
            echo "Commit effectué avec succès !"
            ;;
        2)
            # Modifier tout le message
            echo "Modifiez le message de commit dans l'éditeur qui va s'ouvrir."
            echo "La première ligne sera le titre, le reste sera la description."
            modified_message=$(edit_text "$commit_message")
            modified_title=$(echo "$modified_message" | head -n 1)
            modified_description=$(echo "$modified_message" | tail -n +2)
            
            git commit -m "$modified_title" -m "$modified_description"
            echo "Commit effectué avec succès !"
            ;;
        3)
            # Modifier seulement le titre
            echo "Titre actuel: $commit_title"
            read -p "Nouveau titre: " modified_title
            
            git commit -m "$modified_title" -m "$commit_description"
            echo "Commit effectué avec succès !"
            ;;
        4)
            # Modifier seulement la description
            echo "Description actuelle:"
            echo "$commit_description"
            echo "Modifiez la description dans l'éditeur qui va s'ouvrir."
            modified_description=$(edit_text "$commit_description")
            
            git commit -m "$commit_title" -m "$modified_description"
            echo "Commit effectué avec succès !"
            ;;
        5)
            # Annuler
            echo "Commit annulé. Vous pouvez créer votre commit manuellement."
            ;;
        *)
            echo "Option non valide. Commit annulé."
            ;;
    esac
}

# Exécuter la fonction principale
main "$@"