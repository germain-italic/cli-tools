#!/bin/bash

# Aller à la racine du dépôt
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR" || {
  echo "❌ Not inside a Git repository."
  exit 1
}

# Vérifier si le sous-module est initialisé
if [ ! -d "synology/firewall/.git" ] && [ ! -f "synology/firewall/.git" ]; then
  echo "⚠️ The submodule synology/firewall is not initialized."
  echo "👉 Run './synology/firewall-install.sh' first."
  exit 1
fi

echo "🔄 Updating submodule: synology/firewall/"
cd synology/firewall || {
  echo "❌ Cannot access synology/firewall/"
  exit 1
}

git pull origin master || {
  echo "❌ Failed to pull latest changes."
  exit 1
}

cd "$ROOT_DIR"

# Stage the updated submodule pointer
git add synology/firewall
echo "✅ Submodule updated."
echo "ℹ️ Don't forget to commit the updated pointer:"
echo "   git commit -m \"Update firewall submodule\""
echo "   git push"
