#!/bin/bash

# Ce script supprime une règle du firewall Synology DSM 7.x en se basant sur le hostname
# Usage: ./remove_firewall_hostname.sh <hostname>

# Vérifier si le hostname a été fourni
if [ $# -ne 1 ]; then
    echo "Usage: $0 <hostname>"
    echo "Exemple: $0 maison.ddns.net"
    exit 1
fi

# Hostname à supprimer
HOSTNAME="$1"

# Chemin vers les fichiers de configuration du firewall
FIREWALL_DIR="/usr/syno/etc/firewall.d"

# Obtenir le profil actif
SETTINGS_FILE="$FIREWALL_DIR/firewall_settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Erreur: Fichier de paramètres du firewall introuvable"
    exit 1
fi

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

if [ -z "$PROFILE_FILE" ] || [ ! -f "$PROFILE_FILE" ]; then
    echo "Erreur: Fichier de profil introuvable"
    exit 1
fi

echo "Fichier de profil à modifier: $PROFILE_FILE"

# Faire une sauvegarde du fichier
BACKUP_FILE="${PROFILE_FILE}.backup.$(date +%Y%m%d%H%M%S)"
cp "$PROFILE_FILE" "$BACKUP_FILE"
echo "Sauvegarde créée: $BACKUP_FILE"

# Vérifier si le hostname existe dans le fichier
if ! grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$HOSTNAME\"" "$PROFILE_FILE"; then
    echo "Aucune règle avec le hostname $HOSTNAME n'a été trouvée"
    exit 0
fi

# Extraire l'adresse IP associée au hostname pour la supprimer des règles iptables
IP_ADDRESS=""
if command -v jq >/dev/null 2>&1; then
    IP_ADDRESS=$(jq -r --arg hostname "$HOSTNAME" '.rules.global[] | select(.name == $hostname) | .ipList[0]' "$PROFILE_FILE")
    echo "Adresse IP associée au hostname $HOSTNAME: $IP_ADDRESS"
    
    # Supprimer la règle contenant le hostname
    TMP_FILE=$(mktemp)
    
    jq --arg hostname "$HOSTNAME" '
    .rules.global = (.rules.global | map(
        select(.name != $hostname)
    ))
    ' "$PROFILE_FILE" > "$TMP_FILE"
    
    # Vérifier que le fichier temporaire est valide et non vide
    if [ -s "$TMP_FILE" ] && jq empty "$TMP_FILE" 2>/dev/null; then
        echo "Modification réussie, application des changements"
        cp "$TMP_FILE" "$PROFILE_FILE"
        rm -f "$TMP_FILE"
    else
        echo "Erreur lors de la modification du fichier JSON"
        rm -f "$TMP_FILE"
        exit 1
    fi
else
    echo "jq n'est pas disponible, impossible de supprimer la règle correctement"
    exit 1
fi

# Si une adresse IP a été trouvée, la supprimer des règles iptables
if [ -n "$IP_ADDRESS" ]; then
    echo "Suppression des règles iptables pour $IP_ADDRESS"
    iptables -t filter -D FORWARD_FIREWALL -s "$IP_ADDRESS" -j RETURN 2>/dev/null
    iptables -t filter -D INPUT_FIREWALL -s "$IP_ADDRESS" -j RETURN 2>/dev/null
fi

# Recharger le firewall
echo "Rechargement du firewall..."
if ! /usr/syno/bin/synofirewall --reload; then
    echo "Erreur lors du rechargement du firewall!"
    echo "Restauration de la sauvegarde..."
    cp "$BACKUP_FILE" "$PROFILE_FILE"
    /usr/syno/bin/synofirewall --reload
    echo "Sauvegarde restaurée"
    exit 1
fi

echo "Règle pour le hostname $HOSTNAME supprimée avec succès"

# Vérifier que le hostname a bien été supprimé
if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$HOSTNAME\"" "$PROFILE_FILE"; then
    echo "ATTENTION: Le hostname est toujours présent dans le fichier de configuration"
else
    echo "Vérification réussie: le hostname a bien été supprimé du fichier de configuration"
fi

# Vérifier que l'IP a bien été supprimée des règles iptables, si elle était connue
if [ -n "$IP_ADDRESS" ] && iptables -S | grep -q "$IP_ADDRESS"; then
    echo "ATTENTION: L'IP est toujours présente dans les règles iptables"
else
    echo "Vérification réussie: les règles iptables ont été correctement mises à jour"
fi