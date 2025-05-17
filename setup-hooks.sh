#!/bin/bash

HOOKS_DIR="$(git rev-parse --show-toplevel)/.git/hooks"
CUSTOM_HOOKS_DIR="$(git rev-parse --show-toplevel)/.githooks"

mkdir -p "$CUSTOM_HOOKS_DIR"

# Exemple : post-merge hook
cat > "$CUSTOM_HOOKS_DIR/post-merge" <<'EOF'
#!/bin/bash

cd "$(git rev-parse --show-toplevel)" || exit 1

if [ -x ./synology/firewall-update.sh ]; then
  echo "🔁 Running firewall submodule update..."
  ./synology/firewall-update.sh
fi
EOF

chmod +x "$CUSTOM_HOOKS_DIR/post-merge"

# Copier vers .git/hooks/
cp "$CUSTOM_HOOKS_DIR/post-merge" "$HOOKS_DIR/post-merge"

echo "✅ Hook post-merge installed successfully."
