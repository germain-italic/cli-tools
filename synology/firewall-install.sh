#!/bin/bash

# Aller à la racine du dépôt
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR" || {
  echo "❌ Not inside a Git repository."
  exit 1
}

echo "📦 Initializing Git submodules..."
git submodule update --init --recursive || {
  echo "❌ Failed to initialize submodules."
  exit 1
}
echo "✅ Submodules initialized."

# Installer le hook post-merge
HOOKS_DIR="$ROOT_DIR/.git/hooks"
CUSTOM_HOOK="$HOOKS_DIR/post-merge"

echo "⚙️ Installing Git post-merge hook to auto-update submodule..."

cat > "$CUSTOM_HOOK" <<'EOF'
#!/bin/bash
cd "$(git rev-parse --show-toplevel)" || exit 1
if [ -x ./synology/firewall-update.sh ]; then
  echo "🔁 Running firewall submodule update..."
  ./synology/firewall-update.sh
fi
EOF

chmod +x "$CUSTOM_HOOK"

echo "✅ Git hook installed: .git/hooks/post-merge"
echo
echo "ℹ️ You can now use the Synology Firewall CLI tools in: synology/firewall/"
