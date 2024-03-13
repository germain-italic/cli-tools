#!/bin/bash

# Définir le répertoire racine à scanner
ROOT_DIR="/var/chroot"

# Définir le compteur maximum de répertoires à scanner
MAX_REPOS=1
# Compteur pour suivre le nombre de répertoires traités
count=0

# Fonction pour exécuter les commandes dans les dépôts Git
execute_commands() {
    local repo_dir="$1"

    # Vérifier si le répertoire est un dépôt Git
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        echo "Exécution des commandes dans le dépôt Git : $repo_dir"

        # Se déplacer dans le répertoire du dépôt Git
        cd "$repo_dir" || return

        # Afficher la commande git gc avant l'exécution
        echo "Exécution de la commande git gc..."
        gc_command="git gc --aggressive"
        echo "$gc_command"

        # Exécuter la commande git gc et stocker la sortie
        gc_output=$(git gc --aggressive 2>&1)
        echo "$gc_output"

        # Vérifier s'il y a eu une erreur lors de l'exécution de la commande git gc
        if [ $? -ne 0 ]; then
            echo "Erreur lors de l'exécution de la commande git gc : $gc_output"
        else
            echo "Commande git gc exécutée avec succès."
        fi

        # Afficher la commande git prune avant l'exécution
        echo "Exécution de la commande git prune..."
        prune_command="git prune"
        echo "$prune_command"

        # Exécuter la commande git prune et stocker la sortie
        prune_output=$(git prune 2>&1)
        echo "$prune_output"

        # Vérifier s'il y a eu une erreur lors de l'exécution de la commande git prune
        if [ $? -ne 0 ]; then
            echo "Erreur lors de l'exécution de la commande git prune : $prune_output"
        else
            echo "Commande git prune exécutée avec succès."
        fi

        # Afficher la commande git repack avant l'exécution
        echo "Exécution de la commande git repack..."
        repack_command="git repack -a -d --depth=250 --window=250"
        echo "$repack_command"

        # Exécuter la commande git repack et stocker la sortie
        repack_output=$(git repack -a -d --depth=250 --window=250 2>&1)
        echo "$repack_output"

        # Vérifier s'il y a eu une erreur lors de l'exécution de la commande git repack
        if [ $? -ne 0 ]; then
            echo "Erreur lors de l'exécution de la commande git repack : $repack_output"
        else
            echo "Commande git repack exécutée avec succès."
        fi
    fi
}

# Parcourir tous les répertoires de niveau supérieur dans ROOT_DIR
for dir in "$ROOT_DIR"/*/; do
    # Vérifier si le nombre maximum de répertoires à scanner a été atteint
    if [ "$count" -ge "$MAX_REPOS" ]; then
        echo "Nombre maximum de répertoires à scanner atteint. Arrêt du processus."
        break
    fi

    # Vérifier si le répertoire est un répertoire
    if [ -d "$dir" ]; then
        # Vérifier si le répertoire contient un sous-répertoire .git
        if [ -d "$dir/.git" ]; then
            ((count++))
            # Exécuter les commandes dans le dépôt Git
            execute_commands "$dir"
        fi
    fi
done

# Envoyer le rapport par e-mail
echo "Synthèse des optimisations effectuées : " > report.txt
echo "Commande git gc, git prune et git repack ont été exécutées dans les $count dépôts Git." >> report.txt
echo "Le script a été arrêté après avoir scanné $MAX_REPOS dépôts Git." >> report.txt
mail -s "Rapport d'optimisation des dépôts Git" support@italic.fr < report.txt
cat report.txt
