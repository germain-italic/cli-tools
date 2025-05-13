<?php
// Message par défaut et adresse du destinataire
$message = "Test mail (liste des fichiers à la racine du site) :";
$destinataire = "";

// Vérifie si le formulaire a été soumis
if ($_SERVER["REQUEST_METHOD"] == "POST" && !empty($_POST["destinataire"])) {
    $destinataire = $_POST["destinataire"];

    // Exécute une commande simple et capture la sortie
    // Remplacez 'ls -l' par la commande dont vous souhaitez capturer la sortie
    ob_start(); // Commence la capture de la sortie
    system('ls -l');
    $resultatCommande = ob_get_contents(); // Stocke la sortie dans une variable
    ob_end_clean(); // Termine la capture de la sortie

    // Construit le message
    $message .= "\n\n" . $resultatCommande;

    // En-têtes pour l'email
    $headers = "From: webmaster@example.com\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8";

    // Envoie l'email
    if (mail($destinataire, "Test mail", $message, $headers)) {
        echo "Email envoyé avec succès à " . htmlspecialchars($destinataire) . ".";
    } else {
        echo "Erreur lors de l'envoi de l'email.";
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Envoyer le test mail</title>
</head>
<body>
    <h2>Envoyer le test mail</h2>
    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="post">
        <label for="destinataire">Adresse Email du Destinataire :</label>
        <input type="email" id="destinataire" name="destinataire" required>
        <button type="submit">Envoyer</button>
    </form>
</body>
</html>
