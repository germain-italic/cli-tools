#!/bin/bash

# Ce script vérifie si l'IP associée à un hostname a changé
# et met à jour le firewall en conséquence
# Usage: ./update_home_ip.sh <hostname>

# Configuration
HOSTNAME="italicfrgermru.ddns.net"
IP_HISTORY_FILE="/tmp/home_ip_history.txt"
SCRIPT_DIR="$(dirname "$0")"

# Vérifier si le script d'ajout et de suppression sont présents
if [ ! -f "$SCRIPT_DIR/add_firewall.sh" ] || [ ! -f "$SCRIPT_DIR/remove_firewall.sh" ]; then
    echo "Erreur: Les scripts add_firewall.sh et remove_firewall.sh doivent être dans le même répertoire"
    exit 1
fi

# Rendre les scripts exécutables si nécessaire
chmod +x "$SCRIPT_DIR/add_firewall.sh" "$SCRIPT_DIR/remove_firewall.sh"

# Obtenir l'adresse IP actuelle associée au hostname
echo "Résolution du hostname $HOSTNAME..."
CURRENT_IP=$(dig +short $HOSTNAME)

# Vérifier si la résolution DNS a fonctionné
if [ -z "$CURRENT_IP" ]; then
    echo "Erreur: Impossible de résoudre le hostname $HOSTNAME"
    # On pourrait utiliser nslookup ou host comme alternative
    CURRENT_IP=$(nslookup $HOSTNAME 2>/dev/null | grep -A1 'Name:' | grep 'Address:' | tail -1 | awk '{print $2}')
    
    if [ -z "$CURRENT_IP" ]; then
        CURRENT_IP=$(host $HOSTNAME 2>/dev/null | grep 'has address' | awk '{print $4}')
    fi
    
    if [ -z "$CURRENT_IP" ]; then
        echo "Erreur: Impossible de résoudre le hostname $HOSTNAME avec les méthodes alternatives"
        exit 1
    fi
fi

echo "Adresse IP actuelle pour $HOSTNAME: $CURRENT_IP"

# Créer le fichier d'historique s'il n'existe pas
if [ ! -f "$IP_HISTORY_FILE" ]; then
    echo "Création du fichier d'historique..."
    echo "# Historique des IPs pour $HOSTNAME" > "$IP_HISTORY_FILE"
    echo "# Format: DATE IP" >> "$IP_HISTORY_FILE"
    echo "LAST_IP=" >> "$IP_HISTORY_FILE"
fi

# Lire la dernière IP connue
LAST_IP=$(grep -E "^LAST_IP=" "$IP_HISTORY_FILE" | cut -d'=' -f2)

echo "Dernière IP connue: $LAST_IP"

# Si l'IP a changé
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    echo "L'adresse IP a changé de $LAST_IP à $CURRENT_IP"
    
    # Si une IP précédente existe, la supprimer du firewall
    if [ -n "$LAST_IP" ]; then
        echo "Suppression de l'ancienne règle pour $HOSTNAME..."
        "$SCRIPT_DIR/remove_firewall.sh" "$HOSTNAME"
    fi
    
    # Ajouter la nouvelle IP
    echo "Ajout de la nouvelle IP $CURRENT_IP pour $HOSTNAME..."
    "$SCRIPT_DIR/add_firewall.sh" "$CURRENT_IP" "$HOSTNAME"
    
    # Mettre à jour l'historique
    sed -i "s/^LAST_IP=.*/LAST_IP=$CURRENT_IP/" "$IP_HISTORY_FILE"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $CURRENT_IP" >> "$IP_HISTORY_FILE"
    
    echo "Mise à jour du firewall terminée avec succès"
else
    echo "L'adresse IP n'a pas changé, aucune action nécessaire"
fi