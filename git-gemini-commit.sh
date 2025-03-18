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
    prompt_text="Génère un message de commit concis et descriptif pour les modifications suivantes dans mon dépôt Git : $git_diff. Détails des modifications : $diff_content. Assure-toi que la première ligne est un titre court et concis, puis ajoute une ligne vide suivie d'une description plus détaillée."
    
    # Échapper les caractères spéciaux pour JSON
    prompt_json=$(echo "$prompt_text" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\t/\\t/g')
    
    echo "Consultation de l'API Gemini pour générer un message de commit..."
    
    # Appeler l'API Gemini
    response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$api_key" \
        -H "Content-Type: application/json" \
        -d "{
            \"contents\": [{
                \"parts\": [{
                    \"text\": \"$prompt_json\"
                }]
            }]
        }")
    
    # Extraire le message de commit suggéré en utilisant jq
    commit_message=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)
    
    # Vérifier si le message a été correctement extrait
    if [ -z "$commit_message" ]; then
        error_exit "Impossible d'extraire un message de commit. Vérifiez votre clé API et votre connexion."
    fi
    
    # Afficher le message de commit suggéré
    echo "Message de commit suggéré :"
    echo "$commit_message"
    echo "-----------------------------------------"
    
    # Séparer la première ligne (titre) et le reste (description)
    commit_title=$(echo "$commit_message" | head -n 1)
    commit_description=$(echo "$commit_message" | tail -n +2)
    
    echo "Titre du commit : $commit_title"
    echo "Description du commit :"
    echo "$commit_description"
    echo "-----------------------------------------"
    
    # Demander confirmation
    read -p "Voulez-vous utiliser ce message pour votre commit ? (o/n) : " confirm
    
    if [ "$confirm" = "o" ] || [ "$confirm" = "O" ]; then
        git commit -m "$commit_title" -m "$commit_description"
        echo "Commit effectué avec succès !"
    else
        echo "Commit annulé. Vous pouvez créer votre commit manuellement."
    fi
}

# Exécuter la fonction principale
main "$@"