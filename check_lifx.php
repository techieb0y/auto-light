#!/usr/bin/php
<?php

$authtok = "REDACTED";
$apibase = "https://api.lifx.com/v1";


$which = "id:" . $argv[1];
syslog(LOG_DEBUG, $which);


// echo "*Begin*\n";
$c = curl_init();
$headers = array( "Authorization: Bearer $authtok", "User-Agent: check_lifx/1.0" );
curl_setopt($c, CURLOPT_HTTPHEADER, $headers);
curl_setopt($c, CURLOPT_URL, $apibase . "/lights/" . $which);
curl_setopt($c, CURLOPT_RETURNTRANSFER, true);

// echo "*cURL exec*\n";
$result = curl_exec($c) or die("Error when running curl");

// echo "*cURL result*\n";
// print_r($result);

curl_close($c);

// echo "*JSON Decode*\n";
$parse = json_decode($result, true);

// print_r($parse);

$pulse = $parse[0]["seconds_since_seen"];
if ( isset($pulse) && ($pulse < 900) ) {
	$ret = 0;
	$text = "Recent light update detected";
} else {
	$ret = 2;
	$text = "Update not found for this light";
} // end if

echo $text;
exit($ret);

// echo "*End*\n";

?>
