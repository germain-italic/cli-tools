#!/bin/bash

# Configuration
TARGET_DIR="/media/sf_mp4/Temp"
DESTINATION_DIR="/media/sf_mp4/Completed"

# Mode déplacement toujours activé
MOVE_TORRENTS=1
echo "Mode déplacement activé: les torrents seront déplacés vers $DESTINATION_DIR"

# Fichier de log pour le suivi
LOG_FILE="/home/$USER/transmission_move.log"
echo "$(date) - Début de l'exécution du script" >> "$LOG_FILE"

# Fichier temporaire pour stocker les résultats
TEMP_FILE=$(mktemp)

echo "Recherche des torrents à 100% dans $TARGET_DIR..."
echo "$(date) - Recherche des torrents à 100% dans $TARGET_DIR" >> "$LOG_FILE"
echo "------------------------------------------------------"

# Obtenir la liste des IDs des torrents à 100%
torrent_ids=$(transmission-remote -l | grep "100%" | awk '{print $1}')
total_count=$(echo "$torrent_ids" | wc -w)

echo "Analyse de $total_count torrents à 100%..."
echo "$(date) - Analyse de $total_count torrents à 100%" >> "$LOG_FILE"

# Compteur pour la progression
counter=0
found_count=0
moved_count=0

for id in $torrent_ids; do
  # Mettre à jour et afficher la progression
  counter=$((counter + 1))
  printf "\rProgression: %d/%d (%d%%) - Trouvés: %d" $counter $total_count $((counter * 100 / total_count)) $found_count
  
  # Obtenir les détails du torrent
  torrent_info=$(transmission-remote -t "$id" -i)
  
  # Extraire le nom du torrent
  torrent_name=$(echo "$torrent_info" | grep "Name:" | cut -d: -f2- | sed 's/^ *//')
  
  # Extraire l'emplacement configuré
  location=$(echo "$torrent_info" | grep "Location:" | cut -d: -f2- | sed 's/^ *//')
  
  # Vérifier si le torrent est dans le répertoire cible
  if [[ "$location" == "$TARGET_DIR" ]]; then
    found_count=$((found_count + 1))
    
    # Extraire l'état du torrent
    torrent_state=$(transmission-remote -l | grep "^$id " | awk '{print $6}')
    
    # Extraire la date d'ajout
    date_added=$(echo "$torrent_info" | grep "Date added:" | cut -d: -f2- | sed 's/^ *//')
    
    # Extraire le hash
    hash=$(echo "$torrent_info" | grep "Hash:" | cut -d: -f2- | sed 's/^ *//')
    
    # Vérifier si le fichier existe et obtenir sa date de modification
    file_path="$location/$torrent_name"
    if [[ -e "$file_path" ]]; then
      mod_date=$(stat -c "%Y %y" "$file_path" | sed 's/\.[0-9]*//')
    else
      mod_date="0 Fichier non trouvé"
      echo "$(date) - Fichier non trouvé: $file_path" >> "$LOG_FILE"
      continue  # Passer au torrent suivant
    fi
    
    # Déplacer le torrent
    move_status="Non déplacé"
    echo -e "\nDéplacement du torrent $id: $torrent_name"
    echo "$(date) - Déplacement du torrent $id: $torrent_name" >> "$LOG_FILE"
    
    # Vérifier si le dossier de destination existe, sinon le créer
    if [[ ! -d "$DESTINATION_DIR" ]]; then
      echo "Création du dossier de destination $DESTINATION_DIR"
      echo "$(date) - Création du dossier de destination $DESTINATION_DIR" >> "$LOG_FILE"
      mkdir -p "$DESTINATION_DIR"
    fi
    
    # Déplacer le torrent en utilisant l'API de transmission
    transmission-remote -t "$id" --move "$DESTINATION_DIR"
    
    # Vérifier si le déplacement a réussi
    if [[ $? -eq 0 ]]; then
      move_status="Déplacé vers $DESTINATION_DIR"
      moved_count=$((moved_count + 1))
      echo "$(date) - Succès: $torrent_name déplacé vers $DESTINATION_DIR" >> "$LOG_FILE"
    else
      move_status="Échec du déplacement"
      echo "$(date) - Échec: Impossible de déplacer $torrent_name" >> "$LOG_FILE"
    fi
    
    # Attendre un peu pour que Transmission ait le temps de traiter la demande
    sleep 1
    
    # Ajouter au fichier temporaire avec la date de modification pour le tri
    echo -e "$mod_date\t$id\t$hash\t$torrent_name\t$torrent_state\t$date_added\t$move_status" >> "$TEMP_FILE"
  fi
done

echo # Nouvelle ligne après la barre de progression

# Trier les résultats par date de modification (du plus récent au plus ancien)
if [[ -s "$TEMP_FILE" ]]; then
  echo -e "\nTrouvé $found_count torrents à 100% dans $TARGET_DIR:"
  echo "Déplacé $moved_count torrents vers $DESTINATION_DIR"
  echo "$(date) - Trouvé $found_count torrents, déplacé $moved_count" >> "$LOG_FILE"
  
  echo "------------------------------------------------------"
  echo -e "DATE MODIFICATION\t\tID\tHASH\t\tNOM DU TORRENT\t\tÉTAT\t\tDATE AJOUT\t\tSTATUT"
  echo "------------------------------------------------------"
  sort -nr "$TEMP_FILE" | while read -r line; do
    # Formater la sortie
    mod_date=$(echo "$line" | awk '{print $2, $3}')
    id=$(echo "$line" | awk '{print $4}')
    hash=$(echo "$line" | cut -f3)
    name=$(echo "$line" | cut -f4)
    state=$(echo "$line" | cut -f5)
    date_added=$(echo "$line" | cut -f6)
    move_status=$(echo "$line" | cut -f7)
    
    # Tronquer le hash pour l'affichage
    short_hash="${hash:0:16}..."
    
    echo -e "$mod_date\t$id\t$short_hash\t$name\t$state\t$date_added\t$move_status"
  done
else
  echo -e "\nAucun torrent à 100% trouvé dans $TARGET_DIR"
  echo "$(date) - Aucun torrent à 100% trouvé dans $TARGET_DIR" >> "$LOG_FILE"
fi

# Nettoyer le fichier temporaire
rm "$TEMP_FILE"

echo -e "\nRapport final: $moved_count torrents déplacés vers $DESTINATION_DIR"
echo "$(date) - Fin de l'exécution du script. $moved_count torrents déplacés." >> "$LOG_FILE"
echo -e "\nConsultez le fichier de log pour plus de détails: $LOG_FILE"
