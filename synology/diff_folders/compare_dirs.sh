#!/bin/bash

# ============================================================================
# SCRIPT DE COMPARAISON DE RÉPERTOIRES LOCAL ET DISTANT
# ============================================================================
# 
# DÉPENDANCES :
# Ce script nécessite Python 3 avec pandas et au moins un des modules suivants:
# - xlsxwriter (recommandé pour une meilleure compatibilité Excel)
# - openpyxl (alternative si xlsxwriter n'est pas disponible)
#
# Pour installer les dépendances requises, exécutez :
#
#   sudo apt-get update
#   sudo apt-get install -y python3-pandas python3-xlsxwriter
#
# Si vous utilisez pip au lieu des paquets système :
#
#   pip3 install pandas xlsxwriter --user
#
# Pour une installation dans un environnement virtuel :
#
#   python3 -m venv venv
#   source venv/bin/activate
#   pip install pandas xlsxwriter
#
# ============================================================================

# Chemins des répertoires à comparer (Modifiez ces variables selon vos besoins)
LOCAL_DIR="/mnt/d/mp4/"
REMOTE_HOST="root@nas2"
REMOTE_DIR="/volume1/Emby/"

# Obtenir le chemin du répertoire où se trouve le script
#SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="/mnt/d/Sites/cli-tools/synology/diff_folders"

# Définir le chemin de sortie de l'Excel dans le même répertoire que le script
# Vous pouvez remplacer cette ligne si vous souhaitez spécifier un autre emplacement
OUTPUT_XLSX="${SCRIPT_DIR}/directory_differences.xlsx"
OUTPUT_CSV="${SCRIPT_DIR}/directory_differences.csv"

# Vérifier si le fichier Excel de sortie est déjà ouvert
check_file_access() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        # Tenter d'ouvrir le fichier en écriture
        if ! (exec 3>"$file_path") 2>/dev/null; then
            echo "ERREUR: Le fichier $file_path est actuellement ouvert par une autre application."
            echo "Veuillez fermer le fichier et relancer le script."
            return 1
        else
            # Fermer le descripteur de fichier si le test a réussi
            exec 3>&-
            return 0
        fi
    fi
    return 0
}

# Vérifier que le fichier Excel n'est pas déjà ouvert
if ! check_file_access "${OUTPUT_XLSX}"; then
    exit 1
fi

# Fichiers à exclure lors de la comparaison (les fichiers générés par le script lui-même)
SCRIPT_FILES="directory_differences.xlsx|directory_differences.csv|directory_differences_extensions.csv|directory_differences_missing_on_nas.csv|directory_differences_summary.csv|^Scripts/.*"

# Extensions à exclure (séparées par des |)
# Fichiers sur le NAS mais pas en local à ignorer (générés par Emby)
EXCLUDE_MISSING_LOCALLY="\.nfo$|\.jpg$|\.png$|\.jpeg$|\.bif$|\.srt$|\.sub$|\.idx$"
# Fichiers en local mais pas sur le NAS à ignorer
EXCLUDE_MISSING_ON_NAS="\.torrent$|\.part$|\.!qB$"

# Fichiers temporaires pour stocker les listes et le résultat
LOCAL_LIST="/tmp/local_files.txt"
LOCAL_DIRS="/tmp/local_dirs.txt"
REMOTE_LIST="/tmp/remote_files.txt"
REMOTE_DIRS="/tmp/remote_dirs.txt"
ONLY_LOCAL="/tmp/only_local.txt"
ONLY_REMOTE="/tmp/only_remote.txt"
FILTERED_ONLY_LOCAL="/tmp/filtered_only_local.txt"
FILTERED_ONLY_REMOTE="/tmp/filtered_only_remote.txt"
OPTIMIZED_LOCAL="/tmp/optimized_local.txt"
OPTIMIZED_REMOTE="/tmp/optimized_remote.txt"
ONLY_LOCAL_DIRS="/tmp/only_local_dirs.txt"
ONLY_REMOTE_DIRS="/tmp/only_remote_dirs.txt"

# Fonction pour nettoyer les fichiers temporaires
cleanup() {
    echo "Nettoyage des fichiers temporaires..."
    rm -f "${LOCAL_LIST}" "${LOCAL_DIRS}" "${REMOTE_LIST}" "${REMOTE_DIRS}" "${ONLY_LOCAL}" "${ONLY_REMOTE}" 
    rm -f "${FILTERED_ONLY_LOCAL}" "${FILTERED_ONLY_REMOTE}" "${OPTIMIZED_LOCAL}" "${OPTIMIZED_REMOTE}" 
    rm -f "${ONLY_LOCAL_DIRS}" "${ONLY_REMOTE_DIRS}" "/tmp/exclude_locally.txt" "/tmp/exclude_nas.txt" "/tmp/script_files.txt" 2>/dev/null
    
    # Si le fichier Excel a été créé avec succès, supprimer le fichier CSV
    if [ -f "${OUTPUT_XLSX}" ] && [ -f "${OUTPUT_CSV}" ]; then
        echo "Suppression du fichier CSV temporaire..."
        rm -f "${OUTPUT_CSV}"
    fi
}

# S'assurer que cleanup est appelé même si le script est interrompu
trap cleanup EXIT

echo "Analyse des différences entre les répertoires"
echo "Local : ${LOCAL_DIR}"
echo "Distant : ${REMOTE_HOST}:${REMOTE_DIR}"
echo "Fichier de sortie : ${OUTPUT_XLSX}"
echo "---------------------------------------------------"

# Récupérer la liste des fichiers locaux
echo "Récupération de la liste des fichiers locaux..."
find "${LOCAL_DIR}" -type f | sort > "${LOCAL_LIST}"
echo "Nombre de fichiers locaux trouvés: $(wc -l < ${LOCAL_LIST})"

# Récupérer la liste des répertoires locaux
echo "Récupération de la liste des répertoires locaux..."
find "${LOCAL_DIR}" -type d | sort > "${LOCAL_DIRS}"
echo "Nombre de répertoires locaux trouvés: $(wc -l < ${LOCAL_DIRS})"

# Récupérer la liste des fichiers distants
echo "Récupération de la liste des fichiers distants..."
ssh "${REMOTE_HOST}" "find \"${REMOTE_DIR}\" -type f | sort" > "${REMOTE_LIST}"
echo "Nombre de fichiers distants trouvés: $(wc -l < ${REMOTE_LIST})"

# Récupérer la liste des répertoires distants
echo "Récupération de la liste des répertoires distants..."
ssh "${REMOTE_HOST}" "find \"${REMOTE_DIR}\" -type d | sort" > "${REMOTE_DIRS}"
echo "Nombre de répertoires distants trouvés: $(wc -l < ${REMOTE_DIRS})"

# Enregistrer la liste des fichiers générés par le script
echo "${SCRIPT_FILES}" > "/tmp/script_files.txt"

# Normaliser les chemins pour la comparaison
echo "Normalisation des chemins..."
sed -i "s|${LOCAL_DIR}||g" "${LOCAL_LIST}"
sed -i "s|${LOCAL_DIR}||g" "${LOCAL_DIRS}"
sed -i "s|${REMOTE_DIR}||g" "${REMOTE_LIST}"
sed -i "s|${REMOTE_DIR}||g" "${REMOTE_DIRS}"

# Supprimer les entrées vides
sed -i '/^$/d' "${LOCAL_LIST}"
sed -i '/^$/d' "${LOCAL_DIRS}"
sed -i '/^$/d' "${REMOTE_LIST}"
sed -i '/^$/d' "${REMOTE_DIRS}"

# Supprimer les dossiers spécifiques à Synology
echo "Filtrage des fichiers spécifiques à Synology..."
grep -v "@eaDir" "${REMOTE_LIST}" | grep -v "#recycle" > "${REMOTE_LIST}.tmp"
mv "${REMOTE_LIST}.tmp" "${REMOTE_LIST}"

grep -v "@eaDir" "${REMOTE_DIRS}" | grep -v "#recycle" > "${REMOTE_DIRS}.tmp"
mv "${REMOTE_DIRS}.tmp" "${REMOTE_DIRS}"

# Filtrer les fichiers générés par le script
echo "Filtrage des fichiers générés par le script..."
grep -v -E "${SCRIPT_FILES}" "${LOCAL_LIST}" > "${LOCAL_LIST}.tmp"
mv "${LOCAL_LIST}.tmp" "${LOCAL_LIST}"

grep -v -E "${SCRIPT_FILES}" "${REMOTE_LIST}" > "${REMOTE_LIST}.tmp"
mv "${REMOTE_LIST}.tmp" "${REMOTE_LIST}"

# Retrier les fichiers après les modifications
sort "${LOCAL_LIST}" -o "${LOCAL_LIST}"
sort "${LOCAL_DIRS}" -o "${LOCAL_DIRS}"
sort "${REMOTE_LIST}" -o "${REMOTE_LIST}"
sort "${REMOTE_DIRS}" -o "${REMOTE_DIRS}"

echo "Après normalisation et filtrage:"
echo "Nombre de fichiers locaux: $(wc -l < ${LOCAL_LIST})"
echo "Nombre de répertoires locaux: $(wc -l < ${LOCAL_DIRS})"
echo "Nombre de fichiers distants: $(wc -l < ${REMOTE_LIST})"
echo "Nombre de répertoires distants: $(wc -l < ${REMOTE_DIRS})"

# Comparer les listes de fichiers
echo "Analyse des différences de fichiers..."
comm -23 "${LOCAL_LIST}" "${REMOTE_LIST}" > "${ONLY_LOCAL}"
comm -13 "${LOCAL_LIST}" "${REMOTE_LIST}" > "${ONLY_REMOTE}"

# Comparer les listes de répertoires
echo "Analyse des différences de répertoires..."
comm -23 "${LOCAL_DIRS}" "${REMOTE_DIRS}" > "${ONLY_LOCAL_DIRS}"
comm -13 "${LOCAL_DIRS}" "${REMOTE_DIRS}" > "${ONLY_REMOTE_DIRS}"

echo "Nombre de fichiers uniquement locaux (avant filtrage): $(wc -l < ${ONLY_LOCAL})"
echo "Nombre de fichiers uniquement distants (avant filtrage): $(wc -l < ${ONLY_REMOTE})"
echo "Nombre de répertoires uniquement locaux: $(wc -l < ${ONLY_LOCAL_DIRS})"
echo "Nombre de répertoires uniquement distants: $(wc -l < ${ONLY_REMOTE_DIRS})"

# Filtrer les listes selon les extensions à exclure
if [ -n "$EXCLUDE_MISSING_ON_NAS" ]; then
    echo "Filtrage des fichiers locaux selon les extensions à exclure..."
    grep -v -E "$EXCLUDE_MISSING_ON_NAS" "${ONLY_LOCAL}" > "${FILTERED_ONLY_LOCAL}"
else
    cp "${ONLY_LOCAL}" "${FILTERED_ONLY_LOCAL}"
fi

if [ -n "$EXCLUDE_MISSING_LOCALLY" ]; then
    echo "Filtrage des fichiers distants selon les extensions à exclure..."
    grep -v -E "$EXCLUDE_MISSING_LOCALLY" "${ONLY_REMOTE}" > "${FILTERED_ONLY_REMOTE}"
else
    cp "${ONLY_REMOTE}" "${FILTERED_ONLY_REMOTE}"
fi

# Filtrer les fichiers du script s'ils apparaissent encore dans les différences
grep -v -E "${SCRIPT_FILES}" "${FILTERED_ONLY_LOCAL}" > "${FILTERED_ONLY_LOCAL}.tmp"
mv "${FILTERED_ONLY_LOCAL}.tmp" "${FILTERED_ONLY_LOCAL}"

grep -v -E "${SCRIPT_FILES}" "${FILTERED_ONLY_REMOTE}" > "${FILTERED_ONLY_REMOTE}.tmp"
mv "${FILTERED_ONLY_REMOTE}.tmp" "${FILTERED_ONLY_REMOTE}"

echo "Après filtrage des extensions:"
echo "Nombre de fichiers uniquement locaux: $(wc -l < ${FILTERED_ONLY_LOCAL})"
echo "Nombre de fichiers uniquement distants: $(wc -l < ${FILTERED_ONLY_REMOTE})"

# Enregistrer les patterns d'exclusion dans des fichiers texte pour éviter les problèmes d'échappement
echo "${EXCLUDE_MISSING_LOCALLY}" > /tmp/exclude_locally.txt
echo "${EXCLUDE_MISSING_ON_NAS}" > /tmp/exclude_nas.txt
echo "${SCRIPT_FILES}" > /tmp/script_files.txt

# Exécuter les scripts Python
echo "Optimisation de l'affichage des dossiers manquants..."
python3 "${SCRIPT_DIR}/optimize_dirs.py" \
    "${FILTERED_ONLY_LOCAL}" "${FILTERED_ONLY_REMOTE}" \
    "${ONLY_LOCAL_DIRS}" "${ONLY_REMOTE_DIRS}" \
    "${OPTIMIZED_LOCAL}" "${OPTIMIZED_REMOTE}"

echo "Après optimisation des dossiers:"
echo "Nombre d'entrées locales optimisées: $(wc -l < ${OPTIMIZED_LOCAL})"
echo "Nombre d'entrées distantes optimisées: $(wc -l < ${OPTIMIZED_REMOTE})"

# Vérifier s'il y a des différences après filtrage
if [ ! -s "${FILTERED_ONLY_LOCAL}" ] && [ ! -s "${FILTERED_ONLY_REMOTE}" ]; then
    echo "Aucune différence trouvée entre les deux répertoires après filtrage des extensions !"
    exit 0
fi

# Générer le rapport Excel avec le script Python
echo "Génération du rapport..."
python3 "${SCRIPT_DIR}/generate_report.py" \
    "${OPTIMIZED_LOCAL}" "${OPTIMIZED_REMOTE}" \
    "${FILTERED_ONLY_LOCAL}" "${FILTERED_ONLY_REMOTE}" \
    "${OUTPUT_CSV}" "${OUTPUT_XLSX}" \
    "/tmp/exclude_locally.txt" "/tmp/exclude_nas.txt" "/tmp/script_files.txt"

# Vérifier si les fichiers ont été créés
if [ -f "${OUTPUT_CSV}" ]; then
    echo "Fichier CSV créé avec succès: ${OUTPUT_CSV}"
    echo "Taille du fichier CSV: $(du -h "${OUTPUT_CSV}" | cut -f1)"
fi

if [ -f "${OUTPUT_XLSX}" ]; then
    echo "Fichier Excel créé avec succès: ${OUTPUT_XLSX}"
    echo "Taille du fichier Excel: $(du -h "${OUTPUT_XLSX}" | cut -f1)"
else
    echo "Le fichier Excel n'a pas pu être créé. Utilisez le fichier CSV à la place."
fi

echo ""
echo "Analyse terminée."