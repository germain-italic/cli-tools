#!/bin/bash

# Ce script affiche les règles du firewall avec leur nom et leur adresse IP
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
    # Rechercher le fichier avec le nom du profil
    for f in "$FIREWALL_DIR"/*.json; do
        if [ "$f" != "$SETTINGS_FILE" ] && grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$PROFILE_NAME\"" "$f"; then
            PROFILE_FILE="$f"
            break
        fi
    done
fi

echo "Fichier de profil: $PROFILE_FILE"
echo "------------------------------------------"
echo "| Nom de la règle          | Adresse IP         | Activée |"
echo "------------------------------------------"

if command -v jq >/dev/null 2>&1; then
    jq -r '.rules.global[] | select(.ipList != null and .ipList | length > 0) | [.name, .ipList[0], .enable] | @tsv' "$PROFILE_FILE" | \
    while IFS=$'\t' read -r name ip enabled; do
        # Formater la sortie avec des colonnes de largeur fixe
        printf "| %-22s | %-18s | %-7s |\n" "$name" "$ip" "$enabled"
    done
else
    echo "jq n'est pas disponible, impossible d'afficher les règles"
fi

echo "------------------------------------------"