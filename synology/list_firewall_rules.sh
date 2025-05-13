#!/bin/bash

# Ce script affiche les règles du firewall avec leur nom, leurs adresses IP et leur statut
# Usage: ./list_firewall_rules.sh

FIREWALL_DIR="/usr/syno/etc/firewall.d"
SETTINGS_FILE="$FIREWALL_DIR/firewall_settings.json"

# Déterminer le profil actif
PROFILE_NAME=$(grep -o '"profile"[[:space:]]*:[[:space:]]*"[^"]*"' "$SETTINGS_FILE" | sed -E 's/"profile"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/')
echo "Profil actif: $PROFILE_NAME"

# Trouver le fichier de profil
if [ "$PROFILE_NAME" = "default" ]; then
    PROFILE_FILE="$FIREWALL_DIR/1.json"
elif [ "$PROFILE_NAME" = "custom" ] && [ -f "$FIREWALL_DIR/2.json" ]; then
    PROFILE_FILE="$FIREWALL_DIR/2.json"
else
    for f in "$FIREWALL_DIR"/*.json; do
        if [ "$f" != "$SETTINGS_FILE" ] && grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$PROFILE_NAME\"" "$f"; then
            PROFILE_FILE="$f"
            break
        fi
    done
fi

echo "Fichier de profil: $PROFILE_FILE"
echo "-----------------------------------------------------------------------"
echo "| Nom de la règle               | Adresse(s) IP                    | Activée |"
echo "-----------------------------------------------------------------------"

if command -v jq >/dev/null 2>&1; then
    jq -r '
        .rules.global[]
        | select(.ipList | type == "array" and length > 0)
        | [.name, (.ipList | join(", ")), .enable]
        | @tsv
    ' "$PROFILE_FILE" | while IFS=$'\t' read -r name iplist enabled; do
        printf "| %-28s | %-30s | %-7s |\n" "$name" "$iplist" "$enabled"
    done
else
    echo "jq n'est pas disponible, impossible d'afficher les règles"
fi

echo "-----------------------------------------------------------------------"
