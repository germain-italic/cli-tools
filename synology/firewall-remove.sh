#!/bin/bash

# Aller à la racine du dépôt
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR" || {
  echo "❌ Not inside a Git repository."
  exit 1
}

echo "🧹 Removing Git submodule: synology/firewall"

# Supprimer le fichier d'index du sous-module
git submodule deinit -f synology/firewall

# Supprimer l'entrée de config du fichier .gitmodules
git rm -f synology/firewall

# Supprimer les métadonnées du sous-module
rm -rf .git/modules/synology/firewall

echo "✅ Submodule removed from Git."

# Supprimer physiquement le dossier si encore présent
rm -rf synology/firewall

# Commit de nettoyage
echo "ℹ️ Don't forget to commit the removal:"
echo "   git commit -m \"Remove firewall submodule\""
echo "   git push"
