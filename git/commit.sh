#!/bin/bash

# Chemin du fichier
file="../www/test.txt"

# Ajouter la date et l'heure courante à une nouvelle ligne à la fin du fichier
datetime=$(date "+%Y-%m-%d %H:%M:%S")
echo "$datetime" >> "$file"

# Ajouter le fichier à l'index git
git add "$file"

# Créer un commit avec le message spécifié
commit_message="debug $(date "+%Y-%m-%d %H:%M:%S")"
git commit -m "$commit_message"

# Envoyer le commit via git push
git push
