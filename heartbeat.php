<?php
header("Content-type: text/plain");

$headers = apache_request_headers();
$secret = $headers["X-Auth-Token"];
$compare = "REDACTED";

if ( $secret == $compare ) {
	// Secret knock, do the update
	$file = "/var/lib/nagios3/rw/nagios.cmd";
	if ( !file_exists($file) ) { die("Nagios command file missing"); }
	$fd = fopen($file, "a+");
	$time = time();
	$str = "[$time] PROCESS_HOST_CHECK_RESULT;work-macbook;0;Checkin received via API\n";
	fwrite($fd, $str);
	fclose($fd);
} else {
	// Didn't have the magic password
	header( $_SERVER["SERVER_PROTOCOL"] .  " 401 Unauthorized");
}

// var_dump($headers);

?>
