<?php
$testFileName = "testfile.txt";
$testDirName = "testdir";

// Vérifier si le formulaire de suppression a été soumis
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Supprimer le fichier test
    if (file_exists($testFileName)) {
        unlink($testFileName);
        echo "Fichier '$testFileName' supprimé.<br>";
    }

    // Supprimer le dossier test
    if (is_dir($testDirName)) {
        rmdir($testDirName);
        echo "Dossier '$testDirName' supprimé.<br>";
    }
} else {
    // Tenter de créer un fichier test
    if (file_put_contents($testFileName, "test")) {
        echo "Fichier '$testFileName' créé avec succès.<br>";
    } else {
        echo "Erreur lors de la création du fichier '$testFileName'.<br>";
    }

    // Tenter de créer un dossier test
    if (mkdir($testDirName)) {
        echo "Dossier '$testDirName' créé avec succès.<br>";
    } else {
        echo "Erreur lors de la création du dossier '$testDirName'.<br>";
    }
}

?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Vérification des Droits d'Écriture</title>
</head>
<body>
    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post">
        <button type="submit">Supprimer les fichiers/dossiers créés</button>
    </form>
</body>
</html>
