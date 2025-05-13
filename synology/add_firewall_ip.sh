#!/bin/bash

# Ce script ajoute une IP à la whitelist du firewall Synology DSM 7.x
# en la plaçant avant la règle "deny"
# Usage: ./add_firewall_ip.sh <adresse_ip>

# Vérifier si une adresse IP a été fournie
if [ $# -ne 1 ]; then
    echo "Usage: $0 <adresse_ip>"
    echo "Exemple: $0 192.168.1.100"
    exit 1
fi

# Adresse IP à ajouter
IP_TO_ADD="$1"

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

# Vérifier si l'IP existe déjà dans les règles iptables
if iptables -S | grep -q "$IP_TO_ADD"; then
    echo "INFO: L'adresse IP $IP_TO_ADD est déjà présente dans les règles iptables"
fi

# Nous allons adopter une approche plus simple mais fiable : extraire le contenu JSON,
# le modifier manuellement pour ajouter notre nouvelle règle, puis le réécrire
if command -v jq >/dev/null 2>&1; then
    # Vérifier que le fichier est un JSON valide
    if ! jq empty "$PROFILE_FILE" 2>/dev/null; then
        echo "Erreur: Le fichier de profil n'est pas un JSON valide"
        exit 1
    fi
    
    # Extraire la structure de base du JSON
    JSON_CONTENT=$(cat "$PROFILE_FILE")
    
    # Créer la nouvelle règle sous forme de chaîne JSON
    NEW_RULE='{
        "adapterDirect": 1,
        "blLog": false,
        "chainList": [
          "FORWARD_FIREWALL",
          "INPUT_FIREWALL"
        ],
        "enable": true,
        "ipDirect": 1,
        "ipGroup": 0,
        "ipList": [
          "'$IP_TO_ADD'"
        ],
        "ipType": 0,
        "labelList": [],
        "name": "'$IP_TO_ADD'",
        "policy": 0,
        "portDirect": 0,
        "portGroup": 3,
        "portList": [],
        "protocol": 3,
        "ruleIndex": 999,
        "table": "filter"
      }'
    
    # Trouver la position de la règle deny
    # Rechercher la première règle avec "policy": 1
    DENY_POSITION=$(echo "$JSON_CONTENT" | grep -n '"policy"[[:space:]]*:[[:space:]]*1' | head -1 | cut -d':' -f1)
    
    if [ -z "$DENY_POSITION" ]; then
        echo "Aucune règle deny trouvée. Nous allons ajouter la règle à la fin."
        # Trouver la position de la dernière accolade fermante dans rules.global
        LAST_BRACKET=$(echo "$JSON_CONTENT" | grep -n ']' | tail -1 | cut -d':' -f1)
        
        # Créer un fichier temporaire
        TMP_FILE=$(mktemp)
        
        # Insérer la règle avant la dernière accolade fermante
        head -n $((LAST_BRACKET - 1)) "$PROFILE_FILE" > "$TMP_FILE"
        if [ "$(tail -1 "$TMP_FILE" | tr -d '[:space:]')" != "{" ]; then
            # Si la dernière ligne n'est pas une accolade ouvrante, ajouter une virgule
            echo "," >> "$TMP_FILE"
        fi
        echo "$NEW_RULE" >> "$TMP_FILE"
        tail -n +$((LAST_BRACKET)) "$PROFILE_FILE" >> "$TMP_FILE"
    else
        # Trouver le début de la règle deny (accolade ouvrante)
        DENY_START=$(echo "$JSON_CONTENT" | head -n $DENY_POSITION | grep -n '{' | tail -1 | cut -d':' -f1)
        
        # Créer un fichier temporaire
        TMP_FILE=$(mktemp)
        
        # Insérer la règle avant la règle deny
        head -n $((DENY_START - 1)) "$PROFILE_FILE" > "$TMP_FILE"
        echo "$NEW_RULE," >> "$TMP_FILE"
        tail -n +$((DENY_START)) "$PROFILE_FILE" >> "$TMP_FILE"
    fi
    
    # Vérifier que le fichier temporaire est un JSON valide
    if ! jq empty "$TMP_FILE" 2>/dev/null; then
        echo "Erreur: Le fichier modifié n'est pas un JSON valide"
        echo "Essayons une autre approche..."
        
        # Approche alternative utilisant des marqueurs simples
        # Trouver la section "rules": { "global": [
        RULES_START=$(grep -n '"rules"[[:space:]]*:[[:space:]]*{[[:space:]]*"global"[[:space:]]*:[[:space:]]*\[' "$PROFILE_FILE" | cut -d':' -f1)
        if [ -n "$RULES_START" ]; then
            RULES_START=$((RULES_START + 1))  # Ligne suivante
            
            # Créer un fichier temporaire
            rm -f "$TMP_FILE"
            TMP_FILE=$(mktemp)
            
            # Insérer la règle au début de la section rules.global
            head -n $RULES_START "$PROFILE_FILE" > "$TMP_FILE"
            echo "$NEW_RULE," >> "$TMP_FILE"
            tail -n +$((RULES_START + 1)) "$PROFILE_FILE" >> "$TMP_FILE"
            
            if ! jq empty "$TMP_FILE" 2>/dev/null; then
                echo "Erreur: Échec de l'approche alternative"
                rm -f "$TMP_FILE"
                exit 1
            fi
        else
            echo "Erreur: Impossible de trouver la section rules.global"
            rm -f "$TMP_FILE"
            exit 1
        fi
    fi
    
    # Appliquer les modifications
    mv "$TMP_FILE" "$PROFILE_FILE"
    echo "Modification du fichier JSON réussie"
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

echo "Adresse IP $IP_TO_ADD ajoutée à la whitelist avec succès"

# Vérifier que l'IP est bien dans les règles iptables
if iptables -S | grep -q "$IP_TO_ADD"; then
    echo "Vérification réussie: l'IP est correctement présente dans les règles iptables"
else
    echo "ATTENTION: L'IP n'est pas présente dans les règles iptables"
fi

# La vérification du fichier JSON est simplifiée
if grep -q "$IP_TO_ADD" "$PROFILE_FILE"; then
    echo "Vérification réussie: l'IP a bien été ajoutée au fichier de configuration"
else
    echo "ATTENTION: L'IP ne semble pas être dans le fichier de configuration"
fi