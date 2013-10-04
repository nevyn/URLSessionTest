<?php
$uuid = uniqid();
if($_GET["name"])
    $uuid = $_GET["name"];

$size = getallheaders()["Content-Length"];

file_put_contents("/tmp/access.log", $_SERVER['REMOTE_ADDR']." GET  /upload.php ".$uuid." for ".$size." bytes\nHeaders: ".print_r(getallheaders(), true)."\n", FILE_APPEND);


$f = fopen("php://input", "r");
$received = 0;
$partPerSecond = 10;
while(!feof($f) && $size > 0) {
    $remainingNow = $size/$partPerSecond;
    while($remainingNow > 0 && !feof($f)) {
        $downloaded = strlen(fread($f, $remainingNow));
        $remainingNow -= $downloaded;
        $received += $downloaded;
    }
    $percentReceived = ($received / $size) * 100;
    file_put_contents("/tmp/access.log", $_SERVER['REMOTE_ADDR']." ".$percentReceived."% /upload.php ".$uuid."\n", FILE_APPEND);
    sleep(1);
}

file_put_contents("/tmp/access.log", $_SERVER['REMOTE_ADDR']." ".($received == $size ? "DONE" : @"CANCEL") . " /upload.php ".$uuid."\n", FILE_APPEND);
?>