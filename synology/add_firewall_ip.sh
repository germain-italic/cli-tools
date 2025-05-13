#!/bin/bash

# Ce script ajoute une IP à la whitelist du firewall Synology DSM 7.x
# en utilisant un hostname comme nom de la règle
# Usage: ./add_firewall_hostname.sh <adresse_ip> <hostname>

# Vérifier si les paramètres nécessaires sont fournis
if [ $# -ne 2 ]; then
    echo "Usage: $0 <adresse_ip> <hostname>"
    echo "Exemple: $0 192.168.1.100 maison.ddns.net"
    exit 1
fi

# Adresse IP et hostname
IP_TO_ADD="$1"
HOSTNAME="$2"

# Vérifier le format de l'IP (validation basique)
if ! [[ $IP_TO_ADD =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Erreur: Format d'adresse IP invalide"
    exit 1
fi

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

# Vérifier si le hostname existe déjà dans le fichier
if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$HOSTNAME\"" "$PROFILE_FILE"; then
    echo "Un règle avec le hostname $HOSTNAME existe déjà"
    echo "Utilisez remove_firewall_hostname.sh pour supprimer la règle existante d'abord"
    exit 0
fi

# Nous allons adopter une approche simple mais fiable
if command -v jq >/dev/null 2>&1; then
    # Vérifier que le fichier est un JSON valide
    if ! jq empty "$PROFILE_FILE" 2>/dev/null; then
        echo "Erreur: Le fichier de profil n'est pas un JSON valide"
        exit 1
    fi
    
    # Trouver la position de la règle deny (policy=1)
    DENY_INDEX=$(jq '.rules.global | map(.policy) | index(1)' "$PROFILE_FILE")
    
    if [ "$DENY_INDEX" = "null" ] || [ -z "$DENY_INDEX" ]; then
        echo "Aucune règle deny trouvée. La nouvelle règle sera ajoutée à la fin."
        DENY_INDEX=$(jq '.rules.global | length' "$PROFILE_FILE")
    fi
    
    echo "Position de la règle deny: $DENY_INDEX"
    
    # Créer un fichier temporaire
    TMP_FILE=$(mktemp)
    
    # Créer la nouvelle règle et l'insérer avant la règle deny
    jq --arg ip "$IP_TO_ADD" --arg hostname "$HOSTNAME" --argjson pos "$DENY_INDEX" '
    .rules.global = .rules.global[0:$pos] + [
      {
        "adapterDirect": 1,
        "blLog": false,
        "chainList": ["FORWARD_FIREWALL", "INPUT_FIREWALL"],
        "enable": true,
        "ipDirect": 1,
        "ipGroup": 0,
        "ipList": [$ip],
        "ipType": 0,
        "labelList": [],
        "name": $hostname,
        "policy": 0,
        "portDirect": 0,
        "portGroup": 3,
        "portList": [],
        "protocol": 3,
        "ruleIndex": (.rules.global | map(.ruleIndex) | max + 1),
        "table": "filter"
      }
    ] + .rules.global[$pos:]
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
    echo "jq n'est pas disponible, impossible d'ajouter la règle correctement"
    exit 1
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

echo "Adresse IP $IP_TO_ADD ajoutée à la whitelist avec le nom $HOSTNAME"

# Vérifier que l'IP est bien dans les règles iptables
if iptables -S | grep -q "$IP_TO_ADD"; then
    echo "Vérification réussie: l'IP est correctement présente dans les règles iptables"
else
    echo "ATTENTION: L'IP n'est pas présente dans les règles iptables"
fi

# Vérifier que le hostname est bien dans le fichier de configuration
if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$HOSTNAME\"" "$PROFILE_FILE"; then
    echo "Vérification réussie: le hostname a bien été ajouté au fichier de configuration"
else
    echo "ATTENTION: Le hostname ne semble pas être dans le fichier de configuration"
fi