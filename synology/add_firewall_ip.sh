#!/bin/bash

# Ce script supprime une IP de la whitelist du firewall Synology DSM 7.x
# Usage: ./remove_firewall_ip.sh <adresse_ip>

# Vérifier si une adresse IP a été fournie
if [ $# -ne 1 ]; then
    echo "Usage: $0 <adresse_ip>"
    echo "Exemple: $0 192.168.1.100"
    exit 1
fi

# Adresse IP à supprimer
IP_TO_REMOVE="$1"

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

# Vérifier si l'IP existe dans les règles iptables
if ! iptables -S | grep -q "$IP_TO_REMOVE"; then
    echo "L'adresse IP $IP_TO_REMOVE n'est pas dans les règles iptables"
fi

# Vérifier la structure du JSON et supprimer la règle
if command -v jq >/dev/null 2>&1; then
    # Vérifier si le fichier est un JSON valide
    if ! jq empty "$PROFILE_FILE" 2>/dev/null; then
        echo "Erreur: Le fichier de profil n'est pas un JSON valide"
        exit 1
    fi
    
    # Vérifier si l'IP est dans le fichier JSON
    if ! jq -e --arg ip "$IP_TO_REMOVE" '.rules.global[] | select(.ipList != null and .ipList[] == $ip)' "$PROFILE_FILE" >/dev/null 2>&1; then
        echo "L'adresse IP $IP_TO_REMOVE n'est pas dans la whitelist du fichier de configuration"
    fi
    
    # Créer un fichier temporaire
    TMP_FILE=$(mktemp)
    
    # Supprimer la règle contenant l'IP
    jq --arg ip "$IP_TO_REMOVE" '
    .rules.global = .rules.global | map(
        select(.ipList == null or .ipList[] != $ip)
    )
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

# Supprimer les règles iptables existantes pour cette IP
echo "Suppression des règles iptables pour $IP_TO_REMOVE"
iptables -t filter -D FORWARD_FIREWALL -s "$IP_TO_REMOVE" -j RETURN 2>/dev/null
iptables -t filter -D INPUT_FIREWALL -s "$IP_TO_REMOVE" -j RETURN 2>/dev/null

# Recharger le firewall de manière plus sûre
echo "Rechargement du firewall..."
if ! /usr/syno/bin/synofirewall --reload; then
    echo "Erreur lors du rechargement du firewall!"
    echo "Restauration de la sauvegarde..."
    cp "$BACKUP_FILE" "$PROFILE_FILE"
    /usr/syno/bin/synofirewall --reload
    echo "Sauvegarde restaurée"
    exit 1
fi

echo "Adresse IP $IP_TO_REMOVE supprimée de la whitelist avec succès"

# Vérifier que l'IP a bien été supprimée
if iptables -S | grep -q "$IP_TO_REMOVE"; then
    echo "ATTENTION: L'IP est toujours présente dans les règles iptables"
else
    echo "Vérification réussie: l'IP n'est plus présente dans les règles iptables"
fi

if jq -e --arg ip "$IP_TO_REMOVE" '.rules.global[] | select(.ipList != null and .ipList[] == $ip)' "$PROFILE_FILE" >/dev/null 2>&1; then
    echo "ATTENTION: L'IP est toujours présente dans le fichier de configuration"
else
    echo "Vérification réussie: l'IP a bien été supprimée du fichier de configuration"
fi