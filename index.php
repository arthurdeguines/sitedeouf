<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" href="bootstrap.css">
	<link rel="stylesheet" href="style.css">
    <title>Site sql</title>
</head>
<body>
    <h1>Site sql</h1><hr />

<?php //test
echo strlen('testé');
$but="contacts";
// On créé la requête
// on se connecte à MySQL
// on se connecte à MySQL et on sélectionne la base
$req = "SELECT * FROM contacts";
function changereq($table){

	return "SELECT * FROM $table";
}
if(isset($_GET['but'])){
    $req = changereq($_GET['but']);
}else{
    $req = "SELECT * FROM contacts";
}

function getBut(){
    if(isset($_GET['but'])){
    return $_GET['but'];
}else{
    return "contacts";
}
}

$conn = mysqli_connect('localhost', 'root', '', 'solar_panel');




$reqmenu = "SHOW TABLES FROM solar_panel";

// on envoie la requête
$resmenu = $conn->query($reqmenu);




echo "<div class=\"aside col-2\">";
while ($data = mysqli_fetch_array($resmenu)) {
echo "<a type=\"submit\" class=\"btn btn-success\" href=\"?but=".$data[0]." \">".$data[0]."</a>";
}
echo "</div>";

// On créé la requête


// on envoie la requête

if(isset($_GET['but'])){
$reqentete = "describe ".$_GET['but'];
}else{
    $reqentete = "describe contacts";
}
if(isset($_GET['cmd'])){
$reqsup = "delete from ".getBut()." where id=".$_GET['cmd'];
$ressup = $conn->query($reqsup);
}
$resentete = $conn->query($reqentete);

echo "<div class=\"bod col-10\">";
// on va scanner tous les tuples un par un
echo "<table class=\"table\">

         <thead> 
                 <tr>"; 
                 while ($dataentete = mysqli_fetch_array($resentete)) {
                 echo "<td>".$dataentete[0]."</td>"; 
            	 }
                 echo "<td>Action</td>";
                 echo "</tr> </thead>";
                 
    $res = $conn->query($req);     
$cpt = 0;
while ($datadonne = mysqli_fetch_array($res)) {
// on affiche les résultats
echo "<tr>";
for ($col = 0; $col < sizeof($datadonne)/2; $col++)
{
    echo "<td>".$datadonne[$col]."</td>";
}
echo "<td><a type=\"submit\" class=\"btn btn-danger\" name=\".$cpt.\" href=\"?but=".getBut()."&cmd=".$cpt."\">Supprimer</a>
</td>";
echo "</tr>";
$cpt++;
}
echo "</table>";
echo "</div>";
?>
</body>
</html>