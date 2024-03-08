#!/bin/bash

# Vérifier si le script est lancé en tant que root
if [ "$(id -u)" != "0" ]; then
   echo "Ce script doit être exécuté avec des privilèges root" 1>&2
   exit 1
fi

# Demander le nom de domaine
read -p 'Entrez le nom de domaine du nouveau site (ex : new-site.com) : ' DOMAIN_NAME

# Créer l'utilisateur système et ajouter cet utilisateur au groupe www-data
useradd -m -d /home/"$DOMAIN_NAME" -s /bin/false "$DOMAIN_NAME"
usermod -a -G www-data "$DOMAIN_NAME"


# Générer un mot de passe aléatoire
PASSWORD=$(openssl rand -base64 12)

# Définir le mot de passe pour l'utilisateur
echo "$DOMAIN_NAME:$PASSWORD" | chpasswd

# Afficher le mot de passe pour l'utilisateur
echo "Le mot de passe pour $DOMAIN_NAME est $PASSWORD"


# Créer le répertoire www dans le dossier personnel de l'utilisateur
mkdir /home/"$DOMAIN_NAME"/www
chown "$DOMAIN_NAME":www-data /home/"$DOMAIN_NAME"/www
chmod 755 /home/"$DOMAIN_NAME"

# Copier le fichier de configuration par défaut de PHP-FPM et le modifier
cp /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/"$DOMAIN_NAME".conf
sed -i "s/\[www\]/\[$DOMAIN_NAME\]/g" /etc/php/8.1/fpm/pool.d/"$DOMAIN_NAME".conf
sed -i "s/^user = www-data/user = $DOMAIN_NAME/g" /etc/php/8.1/fpm/pool.d/"$DOMAIN_NAME".conf
sed -i "s/^group = www-data/group = www-data/g" /etc/php/8.1/fpm/pool.d/"$DOMAIN_NAME".conf
sed -i "s|listen = /run/php/php8.1-fpm.sock|listen = /var/run/php/php8.1-fpm_$DOMAIN_NAME.sock|g" /etc/php/8.1/fpm/pool.d/"$DOMAIN_NAME".conf

# Créer le VirtualHost Apache
VHOST_PATH="/etc/apache2/sites-available/$DOMAIN_NAME.conf"
cat <<EOF >"$VHOST_PATH"
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    DocumentRoot /home/$DOMAIN_NAME/www

    <Directory /home/$DOMAIN_NAME/www>
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/var/run/php/php8.1-fpm_$DOMAIN_NAME.sock|fcgi://localhost/"
    </FilesMatch>
</VirtualHost>
EOF

# Activer le nouveau site et redémarrer Apache et PHP-FPM
a2ensite "$DOMAIN_NAME.conf"
systemctl reload apache2
systemctl restart php8.1-fpm

# Exécuter Certbot pour le nouveau domaine (décommentez la ligne suivante pour l'exécuter automatiquement)
# certbot --apache -d "$DOMAIN_NAME"

echo "Configuration terminée pour $DOMAIN_NAME"
