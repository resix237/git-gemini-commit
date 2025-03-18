# Git Gemini Commit

Un utilitaire pour générer automatiquement des messages de commit Git intelligents en utilisant l'API Gemini de Google.

## Prérequis

- Un système Ubuntu ou dérivé
- Git installé
- Une clé API Gemini (obtenue sur https://makersuite.google.com/app/apikey)

## Installation

### Option 1: Installation à partir du paquet Debian

1. Clonez ce dépôt ou téléchargez les fichiers
2. Exécutez le script de création du paquet :
   ```bash
   chmod +x build-package.sh
   ./build-package.sh
   ```
3. Installez le paquet généré :
   ```bash
   sudo dpkg -i git-gemini-commit_1.0.0.deb
   sudo apt-get install -f  # Pour installer les dépendances manquantes si nécessaire
   ```

### Option 2: Installation manuelle

1. Copiez le script `git-gemini-commit` dans un répertoire de votre PATH :
   ```bash
   sudo cp git-gemini-commit /usr/local/bin/
   sudo chmod +x /usr/local/bin/git-gemini-commit
   ```

## Configuration

Configurez votre clé API Gemini :

```bash
git config --global gemini.apikey VOTRE_CLE_API
```

## Utilisation

1. Ajoutez vos modifications à l'index Git comme d'habitude :

   ```bash
   git add .
   ```

2. Au lieu d'utiliser `git commit`, exécutez :

   ```bash
   git-gemini-commit
   ```

3. Le script va:

   - Analyser vos modifications
   - Envoyer les détails à l'API Gemini
   - Générer un message de commit approprié
   - Afficher le message proposé
   - Vous demander de confirmer avant de créer le commit

4. Le message de commit sera formaté avec:
   - Une première ligne comme titre concis
   - Le reste comme description détaillée

## Dépannage

### Problèmes courants

- **Message d'erreur "Aucune clé API configurée"** : Vérifiez que vous avez bien configuré votre clé API avec `git config`.
- **Réponse vide de l'API** : Vérifiez la validité de votre clé API et votre connexion Internet.
- **Erreur "Ce n'est pas un dépôt Git"** : Assurez-vous d'exécuter la commande dans un répertoire Git valide.

### Journaux

En cas de problème, vous pouvez obtenir plus d'informations en activant le mode verbose:

```bash
GIT_GEMINI_VERBOSE=1 git-gemini-commit
```

## Désinstallation

```bash
sudo dpkg -r git-gemini-commit  # Si installé via le paquet .deb
# OU
sudo rm /usr/local/bin/git-gemini-commit  # Si installé manuellement
```

## Personnalisation

Vous pouvez personnaliser le prompt envoyé à Gemini en modifiant la variable `prompt_text` dans le script.
