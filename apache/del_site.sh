#!/bin/bash

# Vérifier si le script est lancé en tant que root
if [ "$(id -u)" != "0" ]; then
   echo "Ce script doit être exécuté avec des privilèges root" 1>&2
   exit 1
fi

# Demander le nom de domaine
read -p 'Entrez le nom de domaine à supprimer (ex : new-site.com) : ' DOMAIN_NAME

# Construire les chemins
VHOST_PATH="/etc/apache2/sites-available/$DOMAIN_NAME.conf"
PHP_FPM_PATH="/etc/php/8.1/fpm/pool.d/$DOMAIN_NAME.conf"
USER_HOME="/home/$DOMAIN_NAME"

# Afficher ce qui va être supprimé
echo "Les éléments suivants seront supprimés :"
[[ -f $VHOST_PATH ]] && echo $VHOST_PATH
[[ -f $PHP_FPM_PATH ]] && echo $PHP_FPM_PATH
[[ -d $USER_HOME ]] && echo $USER_HOME
echo "Utilisateur : $DOMAIN_NAME"

# Demander confirmation
read -p "Confirmez-vous la suppression de ces éléments ? (y/n) " CONFIRMATION
if [[ $CONFIRMATION != "y" ]]; then
    echo "Opération annulée."
    exit 0
fi

# Désactiver le site Apache s'il existe
if [[ -f $VHOST_PATH ]]; then
    a2dissite "$DOMAIN_NAME.conf"
    systemctl reload apache2
    echo "Site Apache désactivé."
fi

# Supprimer le fichier de configuration du VirtualHost Apache
[[ -f $VHOST_PATH ]] && rm -f $VHOST_PATH && echo "$VHOST_PATH supprimé."

# Supprimer le fichier de configuration PHP-FPM
[[ -f $PHP_FPM_PATH ]] && rm -f $PHP_FPM_PATH && echo "$PHP_FPM_PATH supprimé."

# Redémarrer PHP-FPM
systemctl restart php8.1-fpm

# Optionnel : Supprimer le certificat SSL avec Certbot (décommentez si nécessaire)
# certbot delete --cert-name $DOMAIN_NAME

# Supprimer le répertoire utilisateur et son contenu
[[ -d $USER_HOME ]] && rm -rf $USER_HOME && echo "$USER_HOME supprimé."

# Supprimer l'utilisateur système
if id "$DOMAIN_NAME" &>/dev/null; then
    userdel -r "$DOMAIN_NAME"
    echo "Utilisateur $DOMAIN_NAME supprimé."
else
    echo "L'utilisateur $DOMAIN_NAME n'existe pas ou a déjà été supprimé."
fi

echo "Suppression terminée pour $DOMAIN_NAME."
