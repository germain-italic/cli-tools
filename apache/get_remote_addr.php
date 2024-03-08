<?php
// Capture l'adresse IP source de la requête
$ipSource = $_SERVER['REMOTE_ADDR'];

// Afficher ou enregistrer l'adresse IP
echo "Adresse IP source : " . $ipSource;

// Ou enregistrez l'IP dans un fichier pour une consultation ultérieure
file_put_contents('ips_source.txt', $ipSource . "\n", FILE_APPEND);
