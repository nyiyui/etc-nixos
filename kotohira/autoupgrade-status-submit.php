<?php
$remote = $_SERVER['HTTP_X_REAL_IP'];
$hash = file_get_contents('php://input');
$ok = file_put_contents("/var/autoupgrade-status/status/{$remote}", $hash);
if ($ok === false) {
  header("HTTP/1.1 500 Internal Server Error");
  die;
}
echo 'ok';
?>
