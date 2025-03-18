#!/bin/bash

# Créer un alias Git pour faciliter l'utilisation
echo "Configuration d'un alias Git pour git-gemini-commit..."

# Vérifier si l'alias existe déjà
if git config --global --get alias.ai > /dev/null; then
    read -p "Un alias 'git ai' existe déjà. Voulez-vous le remplacer ? (o/n) : " replace_alias
    if [ "$replace_alias" != "o" ] && [ "$replace_alias" != "O" ]; then
        echo "Configuration de l'alias annulée."
        exit 0
    fi
fi

# Configurer l'alias
git config --global alias.ai '!git-gemini-commit'

echo "Alias 'git ai' configuré avec succès."
echo "Vous pouvez maintenant utiliser 'git ai' au lieu de 'git-gemini-commit'."

# Demander à l'utilisateur s'il souhaite configurer sa clé API maintenant
read -p "Voulez-vous configurer votre clé API Gemini maintenant ? (o/n) : " config_key
if [ "$config_key" = "o" ] || [ "$config_key" = "O" ]; then
    read -p "Entrez votre clé API Gemini : " api_key
    git config --global gemini.apikey "$api_key"
    echo "Clé API configurée avec succès."
else
    echo "Vous pourrez configurer votre clé API plus tard avec:"
    echo "git config --global gemini.apikey VOTRE_CLE_API"
fi

echo "Installation et configuration terminées."